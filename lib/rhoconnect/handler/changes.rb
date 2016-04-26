require 'rhoconnect/handler/helpers'
require 'rhoconnect/handler/changes/execute_methods'
require 'rhoconnect/handler/changes/runner'
require 'rhoconnect/handler/changes/pass_through_runner'
require 'rhoconnect/handler/changes/engine'
require 'rhoconnect/handler/changes/hooks'

module Rhoconnect
  module Handler
  	module Changes
  	  def self.registered(app)
  	  	# CUD
		    app.post "/", :rc_handler => :cud, :login_required => true, :admin_required => false,
	                      :source_required => true, :client_required => true, 
		                  :deprecated_route => {:verb => :post, :url => ['/api/application', '/application', '/api/application/queue_updates']} do
		      operation = params[:operation]
		      @model.send operation.to_sym, params["#{operation}_object".to_sym]
		    end

		    app.put "/:id", :rc_handler => :update, :login_required => true, :admin_required => false,
	                        :source_required => true, :client_required => true do
		      @model.update(params[:update_object])
		    end

		    app.delete "/:id", :rc_handler => :delete, :login_required => true, :admin_required => false,
	                           :source_required => true, :client_required => true do
		      @model.delete(params[:delete_object])
		    end
  	  end
  	end
  end
end
