module Rhoconnect
  module Controller  
    class UsersController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint
      
      # show users
      get "/", :admin_required => true, :deprecated_route => {:verb => :post, :url => ['/api/list_users', '/api/user/list_users']} do
        current_app.users.members.to_json
      end
      
      # show user
      get "/:user_id" do
        User.load(params[:user_id]).to_array.to_json
      end
      
      # create user
      post "/", :deprecated_route => { :url => "/api/create_user", :verb => :post } do
        app = current_app
        u = User.create({:login => params[:attributes][:login]})
        u.password = params[:attributes]['password']
        app.users << u.login
        "User created"
      end
      
      # update user
      put "/:user_id", :deprecated_route => {:verb => :post, :url => ["/api/update_user", '/api/user/update_user']} do
        User.load(params[:user_id]).update(params[:attributes])
        "User updated"
      end
      
      # delete user
      delete "/:user_id", :deprecated_route => {:verb => :post, :url => ['/api/delete_user', '/api/user/delete_user']} do
        app = current_app
        User.load(params[:user_id]).delete
        app.users.delete(params[:user_id])
        s_params = {:app_id => APP_NAME,:user_id => params[:user_id]}
        app.sources.each{ |source|
          Source.load(source, s_params).flush_store_data
        }
        "User deleted"
      end
      
      # get user's clients
      get "/:user_id/clients", :admin_required => true, \
                    :deprecated_route => {:verb => :post, :url => ['/api/list_clients', '/api/client/list_clients']} do
        User.load(params[:user_id]).clients.members.to_json
      end
      
      # delete user's client
      delete "/:user_id/clients/:client_id", :admin_required => true, \
                :deprecated_route => {:verb => :post, :url => ['/api/delete_client', '/api/client/delete_client']} do
        Client.load(params[:client_id],{:source_name => '*'}).delete
        User.load(params[:user_id]).clients.delete(params[:client_id])
        "Client deleted"
      end
      
      # get user's docnames
      get "/:user_id/sources/:source_id/docnames", :admin_required => true, \
                :deprecated_route => {:verb => :post, :url => ['/api/list_source_docs', '/api/source/list_source_docs']} do
        res = {}
        s = Source.load(params[:source_id], {:app_id => APP_NAME,:user_id => params[:user_id]})
        [:md,:md_size,:md_copy,:errors].each do |doc|
          db_key = s.docname(doc)
          res.merge!(doc => db_key)
        end
        res.to_json
      end
      
      # get user's DB document
      get "/:user_id/sources/:source_id/docs/:doc", :admin_required => true do
        s = Source.load(params[:source_id], {:app_id => APP_NAME,:user_id => params[:user_id]})
        db_key = s.docname(params[:doc])
        Store.get_db_doc(db_key)
      end
      
      # set user's DB document
      post "/:user_id/sources/:source_id/docs/:doc", :admin_required => true do
        throw :halt, [500, "Unknown user '#{params[:user_id]}'"] unless User.is_exist?(params[:user_id])
      
        s = Source.load(params[:source_id], {:app_id => APP_NAME,:user_id => params[:user_id]})
        db_key = s.docname(params[:doc])
        append_to_doc = params[:append]
        append_to_doc ||= false
        Store.set_db_doc(db_key,params[:data],append_to_doc)
        ''
      end
      
      # ping user's client
      post "/ping", :admin_required => true, :deprecated_route => {:verb => :post, :url => ['/api/ping', '/api/client/ping']} do
        User.ping(params)
      end
    end
  end
end