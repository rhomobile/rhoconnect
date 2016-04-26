require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Middleware
    class BodyContentTypeParser
      # Constants
      #
      CONTENT_TYPE = 'CONTENT_TYPE'.freeze
      POST_BODY = 'rack.input'.freeze
      FORM_INPUT = 'rack.request.form_input'.freeze
      FORM_HASH = 'rack.request.form_hash'.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        if env[CONTENT_TYPE] && env[CONTENT_TYPE].match(/^application\/json/) 
          begin
            if (body = env[POST_BODY].read).length != 0
              # for some reason , if we do not do this
              # Ruby 1.9 will fail
              env[POST_BODY] = StringIO.new(body)
              env.update(FORM_HASH => JSON.parse(body), FORM_INPUT => env[POST_BODY])
            end
          rescue JSON::ParserError => jpe
            log jpe.message + jpe.backtrace.join("\n")
            return [500, {'Content-Type' => 'text/plain'}, ["Server error while processing client data"]]
          end
        end
        @app.call(env)
      end
    end
  end
end