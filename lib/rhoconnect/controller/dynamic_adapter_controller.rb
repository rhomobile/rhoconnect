module Rhoconnect
  module Controller  
    class DynamicAdapterController < Rhoconnect::Controller::Base
      set_default :admin_required, false
      set_default :login_required, true
      set_default :source_required, true
      set_default :client_required, true

      register Rhoconnect::EndPoint

      # QUERY
      get "/:source_name", :rc_handler => :query do
        @model.query(params[:query])
      end
      
      # CUD
      post "/:source_name", :rc_handler => :cud do
        operation = params[:operation]
        @model.send operation.to_sym, params["#{operation}_object".to_sym]
      end

      put "/:source_name/:id", :rc_handler => :update do
        @model.update(params[:update_object])
      end

      delete "/:source_name/:id", :rc_handler => :delete do
        @model.delete(params[:delete_object])
      end
      
      # push objects
      post "/:source_id/push_objects", \
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
      post "/:source_id/push_deletes", \
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
      post "/:source_id/fast_insert", \
            { :admin_required => true, 
              :login_required => false, 
              :source_required => false,
              :client_required => false,
              :deprecated_route => {:verb => :post, :url => ['/api/fast_insert', '/api/source/fast_insert']}
            } do
        do_fast_insert
      end
      
      # fast update
      post "/:source_id/fast_update", \
            { :admin_required => true, 
              :login_required => false, 
              :source_required => false,
              :client_required => false,
              :deprecated_route => {:verb => :post, :url => ['/api/fast_update', '/api/source/fast_update']}
            } do
        do_fast_update
      end
      
      # fast object delete
      post "/:source_id/fast_delete", \
              { :admin_required => true, 
                :login_required => false, 
                :source_required => false,
                :client_required => false,
                :deprecated_route => {:verb => :post, :url => ['/api/fast_delete', '/api/source/fast_delete']}
              } do
        do_fast_delete
      end
      
      private
      def self.rest_path
        "/app/#{Rhoconnect::API_VERSION}"
      end
    end
  end
end