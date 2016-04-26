require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Middleware
    class CurrentApp
      def initialize(app)
        @app = app
      end

      def call(env)
        env[Rhoconnect::CURRENT_APP] = App.load(APP_NAME)
        @app.call(env)
      end
    end
  end
end