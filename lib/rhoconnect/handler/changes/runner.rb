module Rhoconnect
  module Handler
    module Changes
      class Runner
      	attr_accessor :source,:client,:engine,:model,:params,:operations

        def initialize(operations,model,client,route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_CLIENT) unless client
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app

     	    @source,@client = model.source,client
          @model = model
     	    @client.last_sync = Time.now if @client
     	    @params = params
          @operations = operations
     	    @engine = Rhoconnect::Handler::Changes::Engine.new(@operations, @model, route_handler, @params)
        end

        def run
          _process_blobs(params)
          processed = 0
          operations.each do |op|
            key,value = op,params[op]
            processed += _receive_cud(key,value) if value
          end
          @engine.do_cud
        end

        private
        def _receive_cud(operation,cud_params)
          return 0 if not operations.include?(operation)
          # build an Array if Hash (new operations are sequential)
          obj_queue = cud_params
          if cud_params.is_a?Hash
            obj_queue = []
            cud_params.each_pair do |key,obj|
              obj_queue << [key, obj]
            end
          end
          queue_key = params[:queue_key]
          queue_name = (queue_key ? "#{operation}:#{queue_key}" : "#{operation}")
          @source.push_queue(queue_name,@client.id,[[@source.name, obj_queue]],true)
          return 1
        end
        
        def _process_blobs(params)
          unless params[:blob_fields].nil?
            [:create,:update].each do |utype|
              objects = params[utype] || {}
              objects.each do |id,obj|
                params[:blob_fields].each do |field|
                  blob = params["#{field}-#{id}"]
                  obj[field] = @model.store_blob(obj,field,blob)
                end
              end
            end
          end
        end
      end
    end
  end
end