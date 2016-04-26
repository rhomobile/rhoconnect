module Rhoconnect
  module Controller  
    class StoreController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint
      
      get "/:doc", \
                :deprecated_route => {:verb => :post, :url => ['/api/get_db_doc', '/api/source/get_db_doc']} do
        Store.get_db_doc(params[:doc])
      end
      
      post "/:doc", \
                  :deprecated_route => {:verb => :post, :url => ['/api/set_db_doc', '/api/source/set_db_doc'] } do
        append_to_doc = params[:append]
        append_to_doc ||= false
        Store.set_db_doc(params[:doc],params[:data],append_to_doc)
        ''
      end
    end
  end
end