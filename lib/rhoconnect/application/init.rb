# Application root path
require 'rubygems'
require 'bundler'
Bundler.require

ROOT_PATH = File.expand_path('.')

# Debugger support
if ENV['DEBUG'] == 'yes'
  ENV['APP_TYPE'] = 'rhosync'
  ENV['ROOT_PATH'] = ROOT_PATH
  require 'debugger'
end

require 'rhoconnect/server'
require 'rhoconnect/web-console/server'
require 'resque/server'

# Rhoconnect server flags
#Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :run
Rhoconnect::Server.disable :clean_trace
Rhoconnect::Server.enable  :raise_errors
Rhoconnect::Server.set     :root,        ROOT_PATH
Rhoconnect::Server.use     Rack::Static, :urls => ['/data'], :root => Rhoconnect::Server.root
# disable Async mode if Debugger is used
if ENV['DEBUG'] == 'yes'
  Rhoconnect::Server.set :use_async_model, false
end
# bootstrap the application
Rhoconnect.bootstrap(ROOT_PATH)
# Load RhoConnect application controller

# TODO - Move to Rhoconnect.rb??
module Rhoconnect
  def app
    url_map = Rhoconnect.url_map
    unless Rhoconnect.disable_resque_console
      url_map['/resque'] = Resque::Server.new
    end
    unless Rhoconnect.disable_rc_console
      url_map['/console'] = RhoconnectConsole::Server.new
    end
    return Rack::URLMap.new url_map
  end
end