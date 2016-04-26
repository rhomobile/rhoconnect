module Rhoconnect
  module Handler
    module Query
      class Engine
        attr_accessor :source, :model, :route_handler, :params

        include Rhoconnect::Handler::Helpers::AuthMethod
        include Rhoconnect::Handler::Helpers::SourceJob
        include Rhoconnect::Handler::Helpers::Binding

        def initialize(model, route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app
          raise ArgumentError.new('Invalid sync handler') unless route_handler
          # if handler is not bound - bind it to self
        # normally it should be bound to a Controller's instance
        
          @source = model.source
          @route_handler = bind_handler(:sync_handler_method, route_handler)  
          @params = params
          @model = model
        end

        def do_sync
          query_res = nil
          if source.query_queue or source.queue
            query_res = async(:query, source.query_queue || source.queue, params[:query])
          else
            query_res = run_query
          end
          query_res
        end

        def run_query
          query_res = nil
          source.if_need_refresh do
            Rhoconnect::Stats::Record.update("source:query:#{source.name}") do
              if auth_method('login')
                query_res = _execute_query
                auth_method('logoff')
              end
              # re-wind refresh time in case of error
              query_failure = source.exists?(:errors)
              source.rewind_refresh_time(query_failure)
            end
          end
          query_res
        end

        def _execute_query
          errordoc = nil
          docobj = nil
          result = nil
          begin
            errordoc = :errors
            docobj = @source
            [:metadata,:schema].each do |method|
              _get_model_data(method)
            end
            @model.before_query
            @route_handler.call
            result = @model.after_query
            # operation,sync succeeded, remove errors
            docobj.lock(errordoc) do
              docobj.flush_data(errordoc)
            end
          rescue Exception => e
            # store sync,operation exceptions to be sent to all clients for this source/user
            log "Model raised query exception: #{e}"
            log e.backtrace.join("\n")
            docobj.lock(errordoc) do
              docobj.put_data(errordoc,{"query-error"=>{'message'=>e.message}},true)
            end
          end
          # pass through expects result hash
          @source.is_pass_through? ? result : true
        end

        # Metadata Operation; source model returns json
        def _get_model_data(method)
          if @model.respond_to?(method)
            data = @model.send(method)        
            if data
              @source.put_value(method,data)
              if method == :schema
                parsed = JSON.parse(data)
                schema_version = parsed['version']
                raise "Mandatory version key is not defined in model schema method" if schema_version.nil?
                @source.put_value("#{method}_sha1",Digest::SHA1.hexdigest(schema_version))
              else
                @source.put_value("#{method}_sha1",Digest::SHA1.hexdigest(data))
              end          
            end
          end
        end
      end
    end
  end
end