#!/usr/bin/env ruby
require 'rhoconnect/server'
require 'rhoconnect/web-console/server'
require 'resque/server'
if defined?(JRUBY_VERSION)
  require 'puma'
else
  require 'thin'
end

ROOT_PATH = File.expand_path('.')

# Rhoconnect server flags
# Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :run
Rhoconnect::Server.disable :clean_trace
Rhoconnect::Server.enable  :raise_errors
Rhoconnect::Server.set     :root, ROOT_PATH
Rhoconnect::Server.use     Rack::Static, :urls => ['/data'], :root => Rhoconnect::Server.root
# Secret is stored in ~/.rhoconnect.yml
secret = YAML.load_file(File.join(ENV['HOME'], '.rhoconnect.yml'))[Rhoconnect.environment][:secret]
Rhoconnect::Server.set :secret, "#{secret}"

# Disable Async mode if Debugger is used
if ENV['DEBUG'] == 'yes'
  Rhoconnect::Server.set :use_async_model, false
end

# Bootstrap the application
Rhoconnect.bootstrap(ROOT_PATH)

module Rhoconnect
  def app
    url_map = Rhoconnect.url_map
    url_map['/resque'] = Resque::Server.new unless Rhoconnect.disable_resque_console
    url_map['/console'] = RhoconnectConsole::Server.new unless Rhoconnect.disable_rc_console
    
    return Rack::URLMap.new url_map
  end
end

class ApplicationController < Rhoconnect::Controller::AppBase
  register Rhoconnect::EndPoint

  post "/login", :rc_handler => :authenticate,
                 :deprecated_route => {:verb => :post, :url => ['/application/clientlogin', '/api/application/clientlogin']} do
    login, password = params[:login], params[:password]
    true
  end
  get "/rps_login", :rc_handler => :rps_authenticate, :login_required => true do
    login, password = params[:login], params[:password]
    true
  end
end

run Rhoconnect.app
