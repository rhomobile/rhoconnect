module Rhoconnect
  module Controller
    class SystemController < Rhoconnect::Controller::APIBase
      set_default :admin_required, true
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      register Rhoconnect::EndPoint

      get "/appserver", \
                :deprecated_route => {:verb => :post, :url => ['/api/get_adapter', '/api/source/get_adapter']} do
        {:adapter_url => Rhoconnect.appserver}.to_json
      end

      post "/appserver", \
                :deprecated_route => {:verb => :post, :url => ['/api/save_adapter', '/api/source/save_adapter']} do
        Rhoconnect.appserver = params['adapter_url'] || params[:attributes]['adapter_url']
      end

      post "/login", :rc_handler => :admin_authenticate, :admin_required => false, :deprecated_route => {:verb => :post, :url => ['/login', '/api/admin/login']} do
        user = User.authenticate(params[:login], params[:password])
      end

      # Path used on the RhoConnect instance to handle application credentials
      get "/rps_login", :admin_required => false do
        auth = Rack::Auth::Basic::Request.new(request.env)
        if auth.provided? and auth.basic? and auth.credentials
          login, password = auth.credentials
          settings = get_config(Rhoconnect.base_directory)[Rhoconnect.environment]
          if settings and settings[:push_server]
            url = URI.parse(settings[:push_server])
            app_login = url.user
            app_pwd = url.password.nil? ? '' : url.password
            if login == app_login && password == app_pwd
              status(204)
            else
              raise ApiException.new(401, "Invalid RhoConnect Push server credentials")
            end
          else
            raise ApiException.new(500, "Invalid RhoConnect Push settings")
          end
        else
          raise ApiException.new(401, "Invalid Basic Authorization header")
        end
      end

      post "/reset", :deprecated_route => {:verb => :post, :url => ['/api/reset', '/api/admin/reset']} do
        keep_token = current_user.token.value
        Store.flush_all
        Rhoconnect.bootstrap(Rhoconnect.base_directory)
        # restoring previous token value after flushdb
        current_user.token = keep_token
        "DB reset"
      end

      get "/stats", \
                      :deprecated_route => {:verb => :post, :url => ['/api/stats', '/api/admin/stats']} do
        if Rhoconnect.stats == true
          names = params[:names]
          if names
            Rhoconnect::Stats::Record.keys(names).to_json
          else
            metric = params[:metric]
            rtype = Rhoconnect::Stats::Record.rtype(metric)
            if rtype == 'zset'
              # returns [] if no results
              Rhoconnect::Stats::Record.range(metric,params[:start],params[:finish]).to_json
            elsif rtype == 'string'
              Rhoconnect::Stats::Record.get_value(metric) || ''
            else
              raise ApiException.new(404, "Unknown metric")
            end
          end
        else
          raise ApiException.new(500, "Stats not enabled")
        end
      end
    end
  end
end