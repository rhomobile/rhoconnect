module Rhoconnect
  module Handler
  	module Authenticate
  	  module ExecuteMethods
  	  	def execute_authenticate_handler(route_handler)
  	  	  _logout
  	  	  _login(route_handler)
  	  	end

  	  	def execute_admin_authenticate_handler(route_handler)
  	  	  token = ''
  	  	  _logout
  	  	  _login(route_handler)
          u = User.load(params[:login])
          token = _do_get_api_token(params, u)
  	  	end

        def execute_rps_authenticate_handler(route_handler)
          _check_login do
            _rps_login(route_handler) ? status(204) : status(401)
          end
        end

  	  	# helper methods
  	  	private
  	  	def _logout
  	  	  session[:login] = nil
  	  	end

  	  	def _login(route_handler)
  	  	  _check_login do
  	  	  	@handler = Rhoconnect::Handler::Authenticate::Runner.new(current_app, route_handler, params)
  	  	  	user = @handler.run
  	  	  	if user
              session[:login] = user.login
              session[:app_name] = APP_NAME
              status(200)
	          else
	            raise LoginException.new("Unable to authenticate '#{params[:login]}'")
	          end
  	  	  end
  	  	end

        def _rps_login(route_handler)
          res = false
          if current_app
            auth = Rack::Auth::Basic::Request.new(request.env)
            if auth.provided? and auth.basic? and auth.credentials
              params[:login] = auth.credentials.first
              params[:password] = auth.credentials.last
              res = route_handler.call 
            end
          end
          res
        end

  	  	def _check_login
          begin
            yield
          rescue LoginException => le
            throw :halt, [401, le.message]
          rescue Exception => e
            throw :halt, [500, e.message]
          end
        end

	    def _do_get_api_token(params,user)
	      if user and user.admin == 1 and user.token
	        user.token.value 
	      else
	        raise ApiException.new(422, "Invalid/missing API user")
	      end
	    end
  	  end
  	end
  end
end