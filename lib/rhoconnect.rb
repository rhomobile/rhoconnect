require 'redis'
require 'cgi'
require 'json'
require 'base64'
require 'securerandom'
require 'zip'
require 'yaml'
require 'rhoconnect/version'
require 'rhoconnect/document'
require 'rhoconnect/lock_ops'
require 'rhoconnect/store'
require 'rhoconnect/store_orm'
require 'rhoconnect/source'
require 'rhoconnect/user'
require 'rhoconnect/api_token'
require 'rhoconnect/app'
require 'rhoconnect/client'
require 'rhoconnect/read_state'
require 'rhoconnect/jobs/source_job'
require 'rhoconnect/jobs/ping_job'
require 'rhoconnect/middleware/helpers'
require 'rhoconnect/stats/record'
require 'rhoconnect/rho_indifferent_access'
require 'rhoconnect/bulk_data'
require 'rhoconnect/db_adapter'
require 'rhoconnect/model/base'
require 'rhoconnect/model/dynamic_adapter_model'
require 'rhoconnect/model/js_base'

dir = File.join(File.dirname(__FILE__),'..','js-adapters')
require "#{dir}/node"
require "#{dir}/node_channel"

REDIS_URL = 'REDIS' unless defined? REDIS_URL
REDISTOGO_URL = 'REDISTOGO_URL' unless defined? REDISTOGO_URL

# Various module utilities for the store
module Rhoconnect
  APP_NAME = 'application' unless defined? APP_NAME

  class RhoconnectServerError < RuntimeError; end

  # Used by application authenticate to indicate login failure
  class LoginException < RuntimeError; end

  # Used to indicate that the document doesn't belong to the entity
  class InvalidDocumentException < RuntimeError; end

  API_VERSION = 'v1'.freeze

  extend self

  class << self
    attr_accessor :base_directory, :app_directory, :data_directory, :vendor_directory, :redis,
      :log_disabled, :bulk_sync_poll_interval, :stats, :appserver, :api_token,
      :raise_on_expired_lock, :lock_duration, :cookie_expire, :predefined_sources,
      :connection_pool_size, :connection_pool_timeout, :redis_timeout, :store_key_ttl,
      :disable_resque_console, :disable_rc_console, :use_node, :restart_node_on_error, :redis_url,
      :node_channel_timeout
  end

  # this mixin adds the controller into the Application's URL Map
  # register Rhoconnect::EndPoint in the controller's class definition
  module EndPoint
    def self.registered(app)
      Rhoconnect.add_to_url_map(app)
    end
  end

  # Rhoconnect API version
  def add_to_url_map(subclass)
    @controllers_map ||= Set.new
    @controllers_map << subclass
  end

  def remove_from_url_map(subclass)
    @controllers_map.delete(subclass) if @controllers_map
  end

  def url_map
    @controllers_map ||= Set.new
    app_url_map = {}
    @controllers_map.each do |klass|
      if klass.respond_to?(:rest_path) and klass.rest_path.size > 0
        app_url_map[klass.rest_path] = klass.new
      end
    end
    app_url_map['/'] = Rhoconnect::DefaultServer.new
    app_url_map
  end

  ### Begin Rhoconnect setup methods
  # Server hook to initialize Rhoconnect
  def bootstrap(basedir)
    config = get_config(basedir)
    # Initialize Rhoconnect and Resque
    Rhoconnect.base_directory = basedir
    Rhoconnect.app_directory = get_setting(config,environment,:app_directory)
    Rhoconnect.data_directory = get_setting(config,environment,:data_directory)
    Rhoconnect.vendor_directory = get_setting(config,environment,:vendor_directory)
    Rhoconnect.bulk_sync_poll_interval = get_setting(config,environment,:bulk_sync_poll_interval,3600)
    Rhoconnect.redis = get_setting(config,environment,:redis,false)
    Rhoconnect.connection_pool_size ||= get_setting(config,environment,:connection_pool_size,5)
    Rhoconnect.connection_pool_timeout = get_setting(config,environment,:connection_pool_timeout,30)
    Rhoconnect.redis_timeout = get_setting(config,environment,:redis_timeout,30)
    Rhoconnect.api_token = ENV['API_TOKEN'] || get_setting(config,environment,:api_token,false)
    Rhoconnect.log_disabled = get_setting(config,environment,:log_disabled,false)
    Rhoconnect.raise_on_expired_lock = get_setting(config,environment,:raise_on_expired_lock,false)
    Rhoconnect.lock_duration = get_setting(config,environment,:lock_duration)
    Rhoconnect.cookie_expire = get_setting(config,environment,:cookie_expire)  || 31536000
    Rhoconnect.store_key_ttl = get_setting(config, environment, :store_key_ttl) ||  86400
    Rhoconnect.predefined_sources = {}
    yield self if block_given?
    Store.create(Rhoconnect.redis)
    Resque.redis = Rhoconnect.redis.is_a?(Array) ? Rhoconnect.redis[0] : Rhoconnect.redis
    Rhoconnect.base_directory ||= File.join(File.dirname(__FILE__),'..')
    Rhoconnect.app_directory ||= Rhoconnect.base_directory
    Rhoconnect.data_directory ||= File.join(Rhoconnect.base_directory,'data')
    Rhoconnect.vendor_directory ||= File.join(Rhoconnect.base_directory,'vendor')
    Rhoconnect.stats ||= false
    Rhoconnect.disable_rc_console ||= false
    Rhoconnect.disable_resque_console ||= false
    Rhoconnect.use_node = Rhoconnect.use_node.nil? ? true : Rhoconnect.use_node
    Rhoconnect.restart_node_on_error ||= true if Rhoconnect.use_node
    Rhoconnect.node_channel_timeout = get_setting(config, environment, :node_channel_timeout, 30)
    if File.directory?(File.join(Rhoconnect.app_directory,'sources'))
      check_and_add(File.join(Rhoconnect.app_directory,'sources'))
      # post deprecation warning !!!
warning_for_deprecated_sources_dir = <<_MIGRATE_TO_NEW_RHOCONNECT

***** WARNING *****
RhoConnect has detected that you're using deprecated SourceAdapter classes.

  SourceAdapter class support will be removed in RhoConnect 4.1.
  Please, migrate your SourceAdapter classes into RhoConnect Models.

  For more details, see RhoConnect Migration guidelines at
  docs.rhomobile.com

_MIGRATE_TO_NEW_RHOCONNECT
      puts warning_for_deprecated_sources_dir
    end

    check_and_add(File.join(Rhoconnect.app_directory,'models','ruby'))
    start_app(config)
    create_admin_user
  end

  def environment
		(ENV['RHO_ENV'] || ENV['RACK_ENV'] || :development).to_sym
  end

  def start_app(config)
    app = nil
    app_name = APP_NAME
    if App.is_exist?(app_name)
      app = App.load(app_name)
    else
      app = App.create(:name => app_name)
    end
    # load all pre-defined adapters files
    Dir[File.join(File.dirname(__FILE__),'rhoconnect','predefined_adapters','*.rb')].each { |adapter| load adapter }
    # load all Ruby Controller & Model files
    Dir[File.join(Rhoconnect.app_directory,'controllers','ruby','*.rb')].each { |controller_file| require controller_file }
    Dir[File.join(Rhoconnect.app_directory,'{sources,models}','**','*.rb')].each do |adapter_file|
      base_file = File.basename(adapter_file, '.*')
      klazz = camelize(base_file)
      require adapter_file
      unless Object.const_defined?("#{klazz}Controller")
        # add to url map
        Rhoconnect::Controller::SourceAdapterBase.register_controller(klazz)
      end
    end

    # TODO: process sources not only from setting.yml file
    if config and config[Rhoconnect.environment]
      sources = config[:sources] || []
      Source.delete_all
      app.delete_sources
      sources.each do |source_name,fields|
        source_config = source_config(source_name)
        check_for_schema_field!(source_config)
        source_config[:name] = source_name
        Source.create(source_config,{:app_id => app.name})
        app.sources << source_name
      end
    end

    start_nodejs_channels if Rhoconnect.use_node
    # Create associations for all sources
    Source.update_associations(app.sources)
  end

  def start_nodejs_channels(opts = {})
    Node.shell_node(opts)
    NodeChannel.bootstrap(Rhoconnect.node_channel_timeout) if Node.started
  end

  # Generate admin user on first load
  def create_admin_user
    unless User.is_exist?('rhoadmin')
      admin = User.create({:login => 'rhoadmin', :admin => 1})
      admin.password = ENV['PSWRD'] || ''
      admin.create_token
    end
    admin = User.load('rhoadmin')
    Rhoconnect.api_token = admin.token_id
  end

  # Add path to load_path unless it has been added already
  def check_and_add(path)
    $:.unshift path unless $:.include?(path)
  end

  def get_config(basedir)
    # Load settings
    settings_file = File.join(basedir,'settings','settings.yml') if basedir
    if settings_file and File.exist?(settings_file)
      YAML.load_file(settings_file)
    else # Otherwise use setting for blank app
      settings_file = File.join(ENV['HOME'], '.rhoconnect.yml')
      YAML.load_file(settings_file) if File.exist?(settings_file)
    end
  end

  def source_config(source_name)
    source_config = {}
    sources = Rhoconnect.get_config(Rhoconnect.base_directory)[:sources]
    source_config = sources[source_name] unless (sources.nil? or sources[source_name].nil?)
    env_config = Rhoconnect.get_config(Rhoconnect.base_directory)[Rhoconnect.environment]
    force_default = source_config[:force_default]
    source_config.delete(:force_default)
    # apply global env settings
    [:poll_interval, :push_notify].each do |setting|
      def_setting = env_config["#{setting.to_s}_default".to_sym]
      def_setting ||= env_config[setting]
      next unless def_setting
      if source_config[setting].nil? or force_default
        source_config[setting] = def_setting
      end
    end
    source_config
  end

  ### End Rhoconnect setup methods
  def register_predefined_source(source_name)
    return if Rhoconnect.predefined_sources.has_key?(source_name)

    Rhoconnect.predefined_sources[source_name] = {:source_loaded => false}
    # create Sinatra server for the predefined source here
    Rhoconnect::Controller::SourceAdapterBase.register_controller(source_name)
  end

  def create_predefined_source(source_name,params)
    source_data = Rhoconnect.predefined_sources[source_name]
    return unless source_data
    if source_data[:source_loaded] != true
      source_config = Rhoconnect.source_config(source_name)
      source_config[:name] = source_name
      Source.create(source_config,params)
      app = App.load(Rhoconnect::APP_NAME)
      app.sources << source_name
      source_data[:source_loaded] = true
    end
  end

  def check_default_secret!(secret)
    if secret == '<changeme>'
      log "*"*60+"\n\n"
      log "WARNING: Change the session secret in config.ru from <changeme> to something secure."
      log "  i.e. running `rake rhoconnect:secret` in your rhoconnect app directory will generate a secret you could use.\n\n"
      log "*"*60
    end
  end

  def check_for_schema_field!(fields)
    if fields['schema']
      log "ERROR: 'schema' field in settings.yml is not supported anymore, please use source adapter schema method!"
      exit(1)
    end
  end

  # Serializes oav to set element
  def setelement(obj,attrib,value)
    #"#{obj}:#{attrib}:#{Base64.encode64(value.to_s)}"
    "#{obj}:#{attrib}:#{value.to_s}"
  end

  # De-serializes oav from set element
  def getelement(element)
    res = element.split(':',3)
    #[res[0], res[1], Base64.decode64(res[2].to_s)]
    [res[0], res[1], res[2]]
  end

  # Get secure random string
  def get_random_identifier
    SecureRandom.hex
  end

  # Generates new token (64-bit integer) based on # of
  # microseconds since Jan 1 2009
  def get_token
    ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
  end

  # Returns require-friendly filename for a class
  def under_score(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  # Taken from rails inflector
  def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
  end

  def expire_bulk_data(username, partition = :user)
    name = BulkData.get_name(partition,username)
    data = BulkData.load(name)
    data.refresh_time = Time.now.to_i if data
  end

  def unzip_file(file_dir,params)
    uploaded_file = File.join(file_dir, params[:filename])
    begin
      File.open(uploaded_file, 'wb') do |file|
        file.write(params[:tempfile].read)
      end
      Zip::File.open(uploaded_file) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(file_dir,f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) { true }
        end
      end
    rescue Exception => e
      log "Failed to unzip `#{uploaded_file}`"
      raise e
    ensure
      FileUtils.rm_f(uploaded_file)
    end
  end

  def which(command)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    paths = ENV['PATH'].split(File::PATH_SEPARATOR)
    paths.each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{command}#{ext}")
        return exe if File.executable? exe
      end
    end
    return nil
  end

  def lap_timer(msg,start)
    duration = timenow - start
    log "#{msg}: #{duration}"
    timenow
  end

  def start_timer(msg='starting')
    log "#{msg}"
    timenow
  end

  def timenow
    (Time.now.to_f * 1000)
  end

  def log(*args)
    now = Time.now.strftime('%I:%M:%S.%L %p %Y-%m-%d')
    puts "[#{Process.pid}][#{now}] #{args.join}" unless Rhoconnect.log_disabled
  end

  def self.appserver
     Store.get_value("appserver_url")
  end

  def self.appserver=(url)
    Store.set_value("appserver_url",url)
  end

  def self.settings
    @@settings ||= get_config(Rhoconnect.base_directory || ROOT_PATH)[Rhoconnect.environment]
  end

  def self.shutdown
    Rhoconnect::Node.kill_process if Rhoconnect::Node.started
  end

  protected
  def get_setting(config,environment,setting,default=nil)
    res = nil
    res = config[environment][setting] if config and environment
    res || default
  end
end

at_exit do
  Rhoconnect.shutdown
end