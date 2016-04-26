require 'rhoconnect/handler/query'
require 'rhoconnect/handler/changes'
require 'rhoconnect/handler/plugin_callbacks'

module Rhoconnect
  module Handler
  	module Sync
  	  def self.registered(app)
  	  	app.set_default :admin_required, false
    	  app.set_default :login_required, true
    	  app.set_default :source_required, true
    	  app.set_default :client_required, true

  	  	app.register Rhoconnect::Handler::Query
  	  	app.register Rhoconnect::Handler::Changes
  	  	app.register Rhoconnect::Handler::PluginCallbacks

        # source name is available inherently from controller
        app.before do
          params[:source_name] = app._rest_name
          params[:source_id] = app._rest_name
        end
  	  end
  	end
  end
end



