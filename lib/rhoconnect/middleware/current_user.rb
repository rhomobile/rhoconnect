require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Middleware
    class CurrentUser
      
      def initialize(app)
        @app = app
      end

      def call(env)
        #puts "env is *** #{env.inspect}"
        env[Rhoconnect::CURRENT_USER] = extract_current_user(env)
        @app.call(env)
      end

      def extract_current_user(env)
        user = nil
        if User.is_exist?(env['rack.session'][:login])
          user = User.load(env['rack.session'][:login])
        end
        if user and (user.admin == 1 || env['rack.session'][:app_name] == APP_NAME)
          user
        else  
          nil
        end
      end
    end
  end
end