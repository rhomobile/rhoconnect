module Rhoconnect
  module Handler
    module Search
      class Engine
        attr_accessor :source, :client, :model, :route_handler, :params

        include Rhoconnect::Handler::Helpers::AuthMethod
        include Rhoconnect::Handler::Helpers::Binding

        def initialize(model, client, route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_CLIENT) unless client
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app
          raise ArgumentError.new('Invalid sync handler') unless route_handler
          
          @client = client
          @source = model.source
          @model = model
          # if handler is not bound - bind it to self
          # normally it should be bound to a Controller's instance
          @route_handler = bind_handler(:search_handler_method, route_handler)  
          @params = params
        end

        def do_search
          return if auth_method('login',client.id) == false
          res = run_search
          auth_method('logoff',client.id)
          res
        end

        def run_search
          errordoc = nil
          docobj = nil
          result = nil
          begin
            errordoc = :search_errors
            docobj = client
            client.compute_token(:search_token)
            result = @route_handler.call
            client.put_data(:search,result) unless @source.is_pass_through?
            # operation,sync succeeded, remove errors
            docobj.lock(errordoc) do
              docobj.flush_data(errordoc)
            end
          rescue Exception => e
            # store sync,operation exceptions to be sent to all clients for this source/user
            log "Model raised search exception: #{e}"
            log e.backtrace.join("\n")
            docobj.lock(errordoc) do
              docobj.put_data(errordoc,{"search-error"=>{'message'=>e.message}},true)
            end
          end
          # pass through expects result hash
          @source.is_pass_through? ? result : true
        end
      end
    end
  end
end
