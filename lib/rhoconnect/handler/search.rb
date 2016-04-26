require 'rhoconnect/handler/helpers'
require 'rhoconnect/handler/search/execute_methods'
require 'rhoconnect/handler/search/runner'
require 'rhoconnect/handler/search/pass_through_runner'
require 'rhoconnect/handler/search/engine'

module Rhoconnect
  module Handler
  	module Search
  	  def self.registered(app)
	  	# search request
	    app.post "/search", \
	          { :login_required => true,
	          	:client_required => true,
	          	:source_required => false,
	          	:admin_required => false,
	            :rc_handler => :search,
	            :deprecated_route => {:verb => :get, :url => ['/application/search', '/api/application/search']}
	          } do
	      search_params = params[:search]
	      @model.search(search_params)
	    end
	  end
  	end
  end
end
