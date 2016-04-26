$:.unshift File.join(File.dirname(__FILE__),'..')
require 'sinatra/base'
require 'erb'
require 'json'
require 'fileutils'
require 'rhoconnect'

# all middlewares, conditions, handlers - everything, that makes our product so cool!
Dir[File.join(File.dirname(__FILE__),'handler', '*.rb')].each { |mw| require mw }
Dir[File.join(File.dirname(__FILE__),'middleware','**','*.rb')].each { |mw| require mw }
Dir[File.join(File.dirname(__FILE__),'condition','**','*.rb')].each { |mw| require mw }

module Rhoconnect

  class ApiException < Exception
    attr_accessor :error_code
    def initialize(error_code,message)
      super(message)
      @error_code = error_code
    end
  end

  class Server < Sinatra::Base
    set :static,        true
    set :stats,         false
    # default secret
    @secret = '<changeme>'

    class << self
      def set_default(setting, value)
        @default_settings ||= {}
        @default_settings[setting] = value
      end
    end

    def self.paths(verb = nil)
      @paths ||= {}
      return @paths if verb.nil?
      @paths[verb] ||= []
      @paths[verb]
    end

    # Setup route and mimetype for bulk data downloads
    # TODO: Figure out why "mime :data, 'application/octet-stream'" doesn't work
    Rack::Mime::MIME_TYPES['.data'] = 'application/octet-stream'

    include Rhoconnect
    # common conditions
    extend Rhoconnect::Condition::AdminRequired
    extend Rhoconnect::Condition::LoginRequired
    extend Rhoconnect::Condition::SourceRequired
    extend Rhoconnect::Condition::ClientRequired
    extend Rhoconnect::Condition::Verbs
    extend Rhoconnect::Condition::VerifySuccess
    extend Rhoconnect::Condition::AddParameter

    # RC Handlers
    include Rhoconnect::Handler::Query::ExecuteMethods
    include Rhoconnect::Handler::Changes::ExecuteMethods
    register Rhoconnect::Handler::Changes::Hooks
    include Rhoconnect::Handler::Search::ExecuteMethods
    include Rhoconnect::Handler::PluginCallbacks::ExecuteMethods
    include Rhoconnect::Handler::Authenticate::ExecuteMethods

    # Set rhoconnect middleware
    set :use_middleware, Proc.new {
      return false if @middleware_configured # Middleware might be configured only once!

      use Rhoconnect::Middleware::XDomainSessionWrapper
      use Rhoconnect::Middleware::BodyContentTypeParser
      use Rhoconnect::Middleware::Stats
      Rhoconnect::Server.set :secret, @secret unless settings.respond_to?(:secret)
      use Rack::Session::Cookie,
        :key => 'rhoconnect_session', :expire_after => Rhoconnect.cookie_expire,
        :secret => Rhoconnect::Server.secret
      use Rhoconnect::Middleware::CurrentApp
      use Rhoconnect::Middleware::CurrentUser

      @middleware_configured ||= true
    }

    helpers do
      def request_action
        request.env['PATH_INFO'].split('/').last
      end

      def current_user
        @env[Rhoconnect::CURRENT_USER]
      end

      def current_app
        @env[Rhoconnect::CURRENT_APP]
      end

      def request_action
        Rhoconnect.resource_action(request.env)
      end

      def current_client
        @env[Rhoconnect::CURRENT_CLIENT]
      end

      def current_source
        @env[Rhoconnect::CURRENT_SOURCE]
      end

      def catch_all
        begin
          yield
        rescue ApiException => ae
          throw :halt, [ae.error_code, ae.message]
        rescue Exception => e
          log e.message + e.backtrace.join("\n")
          throw :halt, [500, e.message]
        end
      end

      def mark_deprecated_call_and_reroute_api4(verb, new_route, old_verb, old_route, route_handler, filter_handler=nil, klass = nil)
        warning_message = "Use of the #{old_verb.to_s.upcase} #{old_route} is deprecated. Use Rhoconnect API #{Rhoconnect::API_VERSION} instead."
        response.headers['Warning'] = warning_message
        Rhoconnect.log warning_message
        if klass
          klass_instance = klass.new
          klass_instance.helpers.call! env.merge('PATH_INFO' => new_route, 'REQUEST_METHOD' => verb.to_s.upcase)
        else
          execute_api_call(route_handler, filter_handler)
        end
      end

      def execute_api_call(route_handler, filter_handler = nil)
        catch_all do
          proc = route_handler.bind(self)
          res = nil
          if filter_handler
            res = send filter_handler, proc
          else
            res = proc.call
          end
          if params.has_key? :warning
            Rhoconnect.log params[:warning]
            response.headers['Warning'] = params[:warning]
          end
          res
        end
      end
    end

    private
    def self._use_async_framework
      return false if settings.respond_to?(:use_async_model) and settings.use_async_model == false
      return false if @dispatch_framework_initialized

      @dispatch_framework_initialized ||=true
      if (RUBY_VERSION =~ /^1\.9\.\d/ || RUBY_VERSION =~ /^2\.\d+\.\d+/) and not defined?(JRUBY_VERSION)
        begin
          require 'rhoconnect/async'
          register Rhoconnect::Synchrony
        rescue LoadError => e
          # if it fails here - Async can not be used
          settings.use_async_model = false
          warning_for_async_gems = <<_INSTALL_ASYNC_GEMS

***** WARNING *****
Rhoconnect has detected that Ruby 1.9.x is used and tried to initialize Async Framework, but failed:

  #{e.inspect}

Make sure to include the following dependencies into your application's Gemfile:

platforms :ruby_19, :mingw_19 do
  gem 'rack-fiber_pool'
  gem 'async-rack'
end

After that, run 'bundle install' to install the necassary dependency gems.
***** WARNING *****

_INSTALL_ASYNC_GEMS
          puts warning_for_async_gems
        end
      else
        set :use_async_model, false
      end
    end

    class << self
      def new
        # by default, enable this feature
        if not settings.respond_to?(:use_async_model) or settings.use_async_model != false
          set :use_async_model, true
        end
        # this must be called first - because
        # it redefines some of the middleware
        _use_async_framework

        if settings.respond_to?(:stats) and settings.send(:stats) == true
          Rhoconnect.stats = true
        else
          Rhoconnect::Server.disable :stats
          Rhoconnect.stats = false
        end
        Rhoconnect::Server.settings.use_middleware
        #puts "Controller #{self.name} has been initialized with #{middleware.inspect}"
        super
      end
    end

    def initialize
      # Whine about default session secret
      check_default_secret!(Rhoconnect::Server.secret)
      super
    end

    Rhoconnect.log "Rhoconnect Server v#{Rhoconnect::VERSION} started..."

    before do
      cache_control :no_cache
      headers({'pragma'=>'no-cache'})
    end

    def self.api4(resource, route_url, verb = :post, options = {}, &block)
      deprecated_route = options[:deprecated_route]
      options.delete(:deprecated_route)

      # TODO: Re-work deprecation handling as soon as client is updated
      # the only reason we do criss-cross routing is because old-style routes
      # had one root and new-style routes now reside in separate controllers
      rc_handler = options[:rc_handler]
      options.delete(:rc_handler)
      rc_handler_method = nil
      if rc_handler
        rc_handler_method = "execute_#{rc_handler}_handler"
        invoke_hook(:handler_installed, self, rc_handler, verb, route_url, options)
      end
      unless deprecated_route.nil?
        deprecated_urls = deprecated_route[:url].is_a?(String) ? [deprecated_route[:url]] : deprecated_route[:url]
        deprecated_urls.each do |deprecated_url|
          d_verb = deprecated_route[:verb].to_sym
          dep_route_handler = Rhoconnect::DefaultServer.send(:generate_method, :dep_route_handler, &block)

          # build deprecation hash to be used later at run time for re-directing
          dep_info = {}
          dep_info[:klass] = self
          dep_info[:route_handler] = dep_route_handler
          dep_info[:rc_handler_method] = rc_handler_method
          dep_info[:verb] = verb
          dep_info[:route_url] = route_url

          #Rhoconnect::DefaultServer.paths[d_verb] ||= []
          Rhoconnect::DefaultServer.paths(d_verb) << deprecated_url
          Rhoconnect::DefaultServer.deprecated_routes(d_verb)[deprecated_url] ||= {}
          Rhoconnect::DefaultServer.deprecated_routes(d_verb)[deprecated_url][self.name] = dep_info
          Rhoconnect::DefaultServer.send d_verb, deprecated_url, options do
            klass = nil
            req_verb = env['REQUEST_METHOD'].downcase.to_sym
            req_path = env['PATH_INFO']
            # retrieve controller-specific deprecation handler
            if params[:source_name]
              controller_name = "#{params[:source_name]}Controller"
              dep_info = Rhoconnect::DefaultServer.deprecated_routes(req_verb)[req_path][controller_name]
              if dep_info
                klass = dep_info[:klass]
                verb = dep_info[:verb]
                route_url = dep_info[:route_url]
                dep_route_handler = dep_info[:route_handler]
                rc_handler_method = dep_info[:rc_handler_method]
              end
            end
            mark_deprecated_call_and_reroute_api4(verb, route_url, req_verb, req_path, dep_route_handler, rc_handler_method, klass)
          end
        end
      end

      # turn block into UnboundMethod - so that we can bind it later with
      # particular Controller instance
      #self.paths[verb] ||= []
      self.paths(verb) << route_url
      route_handler = send(:generate_method, :route_handler, &block)
      route verb.to_s.upcase, route_url, options do
        execute_api_call(route_handler, rc_handler_method)
      end
    end
  end

  # serves OBSOLETED routes and root
  # TODO - OBSOLETED routes should be removed
  class DefaultServer < Rhoconnect::Server
    helpers Rhoconnect::Handler::Helpers::BulkData

    # to prevent registering the same route several times
    def self.deprecated_routes(verb)
      @deprecated_routes ||= {}
      @deprecated_routes[verb] ||= {}
      @deprecated_routes[verb]
    end

    get '/' do
      redirect "/console/"
    end
  end
end

include Rhoconnect
# load all controllers , starting with base
require 'rhoconnect/controller/base'
Dir[File.join(File.dirname(__FILE__),'controller','**','*.rb')].each { |api| require api }
