module Rhoconnect
  module Controller  
    class SourcesController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint
      
      # get source's params
      get "/:source_id", \
                  :deprecated_route => {:verb => :post, :url => ['/api/get_source_params', '/api/source/get_source_params']} do
        Source.load(params[:source_id],{:app_id => APP_NAME,:user_id => '*'}).to_array.to_json
      end
      
      # get all sources with particular partition type
      get "/type/:partition_type", \
                  :deprecated_route => {:verb => :post, :url => ['/api/list_sources', '/api/source/list_sources']}  do
        sources = App.load(APP_NAME).sources
        if params['partition_type'].nil? or params['partition_type'] == 'all'
          sources.to_json 
        else
          res = []
          sources.each do |name|
            s = Source.load(name,{:app_id => APP_NAME,:user_id => '*'})
            if s and s.partition_type and s.partition_type == params['partition_type'].to_sym
              res << name 
            end
          end  
          res.to_json
        end  
      end
      
      # update source's params
      put "/:source_id" do
        source = Source.load(params[:source_id],
          {:app_id => APP_NAME, :user_id => '*'})
        source.update_fields(params[:data])
        ''
      end
    end
  end
end