Execute.define_task do
  desc "config", "Config", :hide => true
  def config(settings_file=false)
    require 'uri'
    require 'yaml'
    if File.exist?(File.join('settings','settings.yml'))
      settings = YAML.load_file(File.join('settings','settings.yml'))
      rackup_config = "config.ru"
    elsif settings_file
      settings = YAML.load_file(settings_file)
      rackup_config = File.join(File.dirname(__FILE__), '..', 'utilities', 'blank_app.ru')
    elsif File.exist?(File.join(ENV['HOME'], '.rhoconnect.yml'))
      settings = YAML.load_file(File.join(ENV['HOME'], '.rhoconnect.yml'))
      rackup_config = File.join(File.dirname(__FILE__), '..', 'utilities', 'blank_app.ru')
    else
      options = { :syncserver => "http://localhost:#{RHOCONNECT_PORT}",
        :redis => REDIS_SERVER_URL, :push_server => PUSH_SERVER_URL, :api_token => API_TOKEN }
      settings = { :development => options, :test => options, :production => options }
      rackup_config = File.join(File.dirname(__FILE__), '..', 'utilities', 'blank_app.ru')
    end

    environment = (ENV['RHO_ENV'] || ENV['RACK_ENV'] || :development).to_sym # FIXME:
    settings = settings[environment]
    # syncserver settings
    uri = URI.parse(settings[:syncserver])
    port = uri.port unless port
    url = "#{uri.scheme}://#{uri.host}:#{port}"
    settings[:syncserver] = url
    settings[:rackup] = rackup_config
    # redis settings
    redis_conf = settings[:redis]
    settings[:redis] = [redis_conf] if redis_conf.is_a?(String)

    settings
  end
end
