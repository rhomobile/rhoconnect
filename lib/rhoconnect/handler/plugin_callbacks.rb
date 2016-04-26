require 'rhoconnect/handler/plugin_callbacks/execute_methods.rb'
require 'rhoconnect/handler/plugin_callbacks/runner.rb'

module Rhoconnect
  module Handler
  	module PluginCallbacks
  	  def self.registered(app)
  	  	# push objects
	    app.post "/push_objects", \
	            { :rc_handler => :push_objects,
	              :admin_required => true, 
	              :login_required => false, 
	              :source_required => false,
	              :client_required => false,
	              :deprecated_route => {:verb => :post, :url => ['/api/push_objects', '/api/source/push_objects']}
	            } do
	      @model.push_objects(params)
	    end
	    
	    # push_deletes
	    app.post "/push_deletes", \
	          { :rc_handler => :push_deletes,
	            :admin_required => true, 
	            :login_required => false,
	            :source_required => false, 
	            :client_required => false,
	            :deprecated_route => {:verb => :post, :url => ['/api/push_deletes', '/api/source/push_deletes']}
	          } do
	      @model.push_deletes(params)
	    end
	    
	    # fast insert
	    app.post "/fast_insert", \
	          { :admin_required => true, 
	            :login_required => false, 
	            :source_required => false,
	            :client_required => false,
	            :deprecated_route => {:verb => :post, :url => ['/api/fast_insert', '/api/source/fast_insert']}
	          } do
	      do_fast_insert
	    end
	    
	    # fast update
	    app.post "/fast_update", \
	          { :admin_required => true, 
	            :login_required => false, 
	            :source_required => false,
	            :client_required => false,
	            :deprecated_route => {:verb => :post, :url => ['/api/fast_update', '/api/source/fast_update']}
	          } do
	      do_fast_update
	    end
	    
	    # fast object delete
	    app.post "/fast_delete", \
	            { :admin_required => true, 
	              :login_required => false, 
	              :source_required => false,
	              :client_required => false,
	              :deprecated_route => {:verb => :post, :url => ['/api/fast_delete', '/api/source/fast_delete']}
	            } do
	      do_fast_delete
	    end
  	  end
  	end
  end
end