require 'rhoconnect/handler/helpers.rb'
require 'rhoconnect/handler/query/execute_methods.rb'
require 'rhoconnect/handler/query/runner.rb'
require 'rhoconnect/handler/query/pass_through_runner.rb'
require 'rhoconnect/handler/query/engine.rb'

module Rhoconnect
  module Handler
  	module Query
  	  def self.registered(app)
	  	  app.get "/", :rc_handler => :query, :login_required => true, :admin_required => false,
                     :source_required => true, :client_required => true, 
                     :deprecated_route => {:verb => :get, :url => ['/api/application', '/application', '/api/application/query']} do
      	  @model.query(params[:query])
    	 end
	    end
  	end
  end
end
