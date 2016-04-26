require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Middleware
    class Stats
      def initialize(app)
        @app = app
      end

      def call(env)
        if Rhoconnect.stats || Rhoconnect::Server.stats
          start = Time.now.to_f
          status, headers, body = @app.call(env)
          finish = Time.now.to_f
          metric = "http:#{env['REQUEST_METHOD']}:#{env['PATH_INFO']}"
          source_name = env['rack.request.query_hash']["source_name"] if env['rack.request.query_hash']
          metric << ":#{source_name}" if source_name
          Rhoconnect::Stats::Record.save_average(metric,finish - start)
          [status, headers, body]
        else
          status, headers, body = @app.call(env)
          [status, headers, body]
        end
      end
    end
  end
end