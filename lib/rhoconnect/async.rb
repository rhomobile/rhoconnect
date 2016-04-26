require 'rack/fiber_pool'
require 'async-rack'
require 'eventmachine'

module Rhoconnect
  module Synchrony
    def setup_sessions(builder)
      options = {}
      if settings.respond_to?(:fiberpool_size)
        options[:size] = settings.fiberpool_size
      end
      options[:rescue_exception] = handle_exception
      builder.use Rack::FiberPool, options unless test?
      builder.use Rhoconnect::Middleware::Async, options
      super
    end

    def handle_exception
      Proc.new do |env, e|
        if settings.show_exceptions?
          request = Sinatra::Request.new(env)
          printer = Sinatra::ShowExceptions.new(proc{ raise e })
          s, h, b = printer.call(env)
          [s, h, b]
        else
          [500, {}, ""]
        end
      end
    end
  end

  module Middleware
    class Async
      def initialize(app, opts={})
        @app = app
        yield self if block_given?
      end

      def call(env)
        f = Fiber.current
        # making a copy is crucial here
        # otherwise 'env' will not be the same
        # in the deferred execution
        aenv = env.dup
        operation = proc {
          res = nil
          aenv['REQUEST_THREAD'] = Thread.current
          if(aenv['RHO_ABORT_PROCESS'])
            res = [500, 'Request is aborted']
          else
            res = @app.call(aenv)
          end
          res
        }
        result = nil
        callback = proc { |proc_res| result = proc_res; f.resume }

        EventMachine.defer operation, callback
        Fiber.yield
        result
      end
    end
  end

#   module AsyncHelpers
#     #def self.included(klass)
#     #  (klass.instance_methods & self.instance_methods).each do |method|
#     #    klass.instance_eval{remove_method method.to_sym}
#     #  end
#     #end
#
#     def catch_all
#       res = nil
#       begin
#         res = catch(:halt) { yield }
#       rescue ApiException => ae
#         res = [ae.error_code, ae.message]
#       rescue Exception => e
#         log e.message + e.backtrace.join("\n")
#         res = [500, e.message]
#       end
#       res
#     end
#
#     def execute_api_call(&block)
#       f = Fiber.current
#       operation = proc {
#         catch_all do
#           puts " we are processing the route #{self.inspect}"
#           method = self.class.send(:generate_method, "calling_method", &block)
#           #method = instance_method "calling_method"
#           #remove_method "calling_method"
#
#           #method = Sinatra::Base.generate_method("calling_method", &block)
#           proc = method.bind(self)
#           res = proc.call
#           #res = yield
#           if params.has_key? :warning
#             Rhoconnect.log params[:warning]
#             response.headers['Warning'] = params[:warning]
#           end
#           res
#         end
#       }
#       result = nil
#       callback = proc { |proc_res| result = proc_res; f.resume }
#
#       EventMachine.defer operation, callback
#       Fiber.yield
#       # we can not throw exceptions across threads
#       # so we analyze it in the main thread after the
#       # request has been processed and if result
#       # has error code - then we throw :halt here
#       if Array === result and Fixnum === result.first
#         throw :halt, result
#       end
#       result
#     end
#   end
end