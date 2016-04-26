module Rhoconnect
  module Controller
    class ClientsController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint
          
      post "/", :admin_required => false, :login_required => true, \
          :deprecated_route => {:verb => :get, :url => ['/application/clientcreate', '/api/application/clientcreate']} do
        content_type :json
        client = Client.create(:user_id => current_user.id,:app_id => current_app.id)
        client.update_fields(params)
        { "client" => { "client_id" =>  client.id.to_s } }.to_json
      end
      
      post "/:client_id/register", :admin_required => false, :login_required => true, \
                    :deprecated_route => {:verb => :post, :url => ['/application/clientregister', '/api/application/clientregister'] } do
        cur_client = extract_current_client
        if cur_client.nil? and current_user and current_app
          fields = {:user_id => current_user.id}
          fields[:id] = params[:client_id].to_s
          fields[:app_id] = current_app.id
          cur_client = Client.create(fields)
        end
        cur_client.update_fields(params)
        status 200
      end
      
      post "/:client_id/reset", :admin_required => false, :login_required => true, :client_required => true, \
                  :deprecated_route => {:verb => :get, :url => ['/application/clientreset', '/api/application/clientreset']} do
        # Resets the store for a given app,client
        if params == nil or params[:sources] == nil
          current_client.flush_all_documents
        else
          params[:sources].each do |source|
            current_client.flush_source_documents(source['name'])
          end
        end
        status 200
      end
      
      get "/:client_id/sources/:source_id/docs/:doc" do
        c = Client.load(params[:client_id],{:source_name => params[:source_id]})
        c.get_db_doc(params[:doc])
      end
      
      post "/:client_id/sources/:source_id/docs/:doc" do
        c = Client.load(params[:client_id],{:source_name => params[:source_id]})
        append_to_doc = params[:append]
        append_to_doc ||= false
        c.set_db_doc(params[:doc], params[:data],append_to_doc)
        ''
      end
      
      get "/:client_id", \
                      :deprecated_route => {:verb => :post, :url => ['/api/get_client_params', '/api/client/get_client_params']} do
        Client.load(params[:client_id],{:source_name => '*'}).to_array.to_json
      end
      
      get "/:client_id/sources/:source_id/docnames", \
                      :deprecated_route => {:verb => :post, :url => ['/api/list_client_docs', '/api/client/list_client_docs']} do
        result = ""
        Rhoconnect::Stats::Record.update('clientdocs') do
          c = Client.load(params[:client_id],{:source_name => params[:source_id]})
          res = {}
          Client.valid_doctypes.each do |doc, doctype|
            db_key = c.docname(doc)
            res.merge!(doc => db_key)
          end
          result = res.to_json
        end
        result
      end
    end
  end
end