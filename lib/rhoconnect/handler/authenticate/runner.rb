module Rhoconnect
  module Handler
  	module Authenticate
  	  class Runner
  	  	attr_accessor :app, :route_handler, :params

  	  	include Rhoconnect::Handler::Helpers::Binding

  	  	def initialize(app, route_handler, params = {})
  	  	  raise ArgumentError.new('Invalid app') unless app
  	  	  raise ArgumentError.new('Invalid authenticate handler') unless route_handler
  	  	  @app = app
  	  	  @route_handler = bind_handler(:authenricate_handler_method, route_handler)
  	  	  @params = params
  	  	end

  	  	def run
          if params[:login].nil? or params[:login].empty?
            return false
          end
          user = _do_authenticate
  	  	end

  	  	private
  	  	def _do_authenticate
  	  	  user = nil
  	  	  if params[:login] == 'rhoadmin'
          	user = @route_handler.call
  	  	  else 
  	  	  	if Rhoconnect.appserver
        	    auth_result = Rhoconnect::Model::DynamicAdapterModel.authenticate(params[:login],params[:password])
      	    else
        	    auth_result = @route_handler.call
            end
      	    if auth_result
              params[:login] = auth_result if auth_result.is_a? String
              user = User.load(params[:login]) if User.is_exist?(params[:login])
              if not user
                user = User.create(:login => params[:login])
                app.users << user.id
              end
            end
          end
          user
        end
  	  end
  	end
  end
end