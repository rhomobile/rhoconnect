module Rhoconnect
  module Handler
    module Changes
      class Engine
        attr_accessor :source, :model, :route_handler, :params, :operations

        include Rhoconnect::Handler::Helpers::SourceJob
        include Rhoconnect::Handler::Helpers::Binding
        include Rhoconnect::Handler::Helpers::AuthMethod

        def initialize(operations, model, route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app
          raise ArgumentError.new('Invalid CUD handler') unless route_handler
          
          @source = model.source
          # if handler is not bound - bind it to self
          # normally it should be bound to a Controller's instance
          @route_handler = bind_handler(:cud_handler_method, route_handler)  
          @params = params
          @model = model
          @operations = operations
        end

        def do_cud
          if source.cud_queue or source.queue
            async(:cud,source.cud_queue || source.queue)
          else
            run_cud
          end   
        end

        # Pass through CUD to adapter, no data stored
        def do_pass_through_cud
          return if auth_method('login') == false
          res,processed_objects = {},[]
          begin
            operations.each do |op|
              objects = params[op]
              params[:operation] = op if objects
              objects.each do |key,value|
                case op
                when 'create'
                  params[:create_object] = value
                  @route_handler.call
                when 'update'
                  value['id'] = key
                  params[:update_object] = value
                  @route_handler.call
                when 'delete'
                  value['id'] = key
                  params[:delete_object] = value
                  @route_handler.call
                end
                processed_objects << key
              end if objects
            end
          rescue Exception => e
            log "Error in pass through method: #{e.message}"
            res['error'] = {'message' => e.message } 
          end
          auth_method('logoff')
          res['processed'] = processed_objects
          res.to_json
        end
        
        def run_cud
          operations.each do |op|
            send op.to_sym
          end
        end

        # CUD Operations
        def create
          _measure_and_process_cud('create')
        end
        
        def update
          _measure_and_process_cud('update')
        end
        
        def delete
          _measure_and_process_cud('delete')
        end

        private
        def _measure_and_process_cud(operation)
          Rhoconnect::Stats::Record.update("source:#{operation}:#{@source.name}") do
            params[:operation] = operation
            _process_cud(operation)
            params.delete(:operation)
          end
        end

        def _process_create(modified_recs,key,value)
          params[:create_object] = value
          link = route_handler.call
          # Store object-id link for the client
          # If we have a link, store object in client document
          # Otherwise, store object for delete on client
          modified_recs.each do |modified_rec|
            if link
              modified_rec[:links] ||= {}
              modified_rec[:links][modified_rec[:key]] = { 'l' => link.to_s }
              modified_rec[:creates] ||= {}
              modified_rec[:creates][link.to_s] = value
            else
              modified_rec[:deletes] ||= {}
              modified_rec[:deletes][modified_rec[:key]] = value
            end
          end
        end
        
        def _process_update(modified_recs,key,value)
          # Add id to object hash to forward to backend call
          value['id'] = key
          params[:update_object] = value
          # Perform operation
          route_handler.call
        end
        
        def _process_delete(modified_recs,key,value)
          value['id'] = key
          params[:delete_object] = value
          route_handler.call
          # Perform operation
          modified_recs.each do |modified_rec|
            modified_rec[:dels] ||= {}
            modified_rec[:dels][modified_rec[:key]] = value
          end
        end
        
        def _process_cud(operation)
          # take everything from the queue and erase it
          # so that no other process will be able to process it again
          operation_data = []
          client_ids = []
          queue_key = params[:queue_key]
          queue_name = (queue_key ? "#{operation}:#{queue_key}" : "#{operation}")

          operation_data,client_ids = @source.process_queue(queue_name)
          invalid_meta = @model.run_validators(operation,operation_data,client_ids)

          # load all clients involved in the current queue
          processed_clients = {}
          user_sorted_data = {}
          client_ids.each_with_index do |client_id, index|
            processed_clients[client_id] = Client.load(client_id,{:source_name => @source.name}) unless processed_clients[client_id]
            client = processed_clients[client_id]
            user_sorted_data[client.user_id] ||= []
            # sort by user (so that login/logoff is called exactly once per operation)
            user_sorted_data[client.user_id] << index
          end

          errors,links,deletes,creates,dels = {},{},{},{},{}
          user_sorted_data.each do |user_id, user_entries|
            # call login
            # Call on source adapter to process individual object
            # NOTE: call should be made from the correct model instance
            model.source = Source.load(@source.name,
                    {:user_id => user_id,:app_id => APP_NAME})
            next if auth_method('login') == false
            user_entries.each do |index|
              client_operation_data = operation_data[index]
              client_id = client_ids[index]
              client = processed_clients[client_id]
            
              # for now - each client operation data can have only one entry (single source CUD)
              # TODO: should be fixed for multi-source CUD
              source_id = client_operation_data[0][0]
              source_operation_data = client_operation_data[0][1]
              current_invalid_meta = invalid_meta[index] || {}
              current_invalid_source_meta = current_invalid_meta[source_id] || {}
              record_index = 0
              source_operation_data.each do |source_entry|
                begin
                  key = source_entry[0]
                  value = source_entry[1]
                  continue_loop = true
                  modified_recs = [{:client_id => client_id, :key => key, :value => value }]
                  record_invalid_meta = current_invalid_source_meta[record_index] || {}
                  # remove processed entries
                  source_operation_data = source_operation_data.drop(1)
                  record_index += 1
                
                  # skip the rec - if it is a duplicate of some other record
                  next if record_invalid_meta[:duplicate_of]
                
                  # prepare duplicate docs
                  duplicates = record_invalid_meta[:duplicates] || {}
                  duplicates.each do |duplicate|
                    modified_recs << duplicate
                  end
                
                  # raise conflict error if record is marked with one
                  raise Rhoconnect::Model::ObjectConflictErrorException.new(record_invalid_meta[:error]) if record_invalid_meta[:error]
                
                  case operation
                  when 'create'
                    _process_create(modified_recs,key,value)
                  when 'update'
                    _process_update(modified_recs,key,value)
                  when 'delete'
                    _process_delete(modified_recs,key,value)
                  end
                rescue Exception => e
                  log "Model raised #{operation} exception: #{e}"
                  log e.backtrace.join("\n")
                  continue_loop = false
                  modified_recs.each do |modified_rec|
                    modified_rec[:errors] ||= {}
                    modified_rec[:errors][modified_rec[:key]] = modified_rec[:value]
                    modified_rec[:errors]["#{modified_rec[:key]}-error"] = {'message'=>e.message}
                  end
                end
              
                { :errors => errors, 
                  :links => links, 
                  :deletes => deletes, 
                  :creates => creates, 
                  :dels => dels }.each do |doc_name, doc|
                  modified_recs.each do |modified_rec|
                    doc[modified_rec[:client_id]] ||= {}
                    next unless modified_rec[doc_name]
                    doc[modified_rec[:client_id]].merge!(modified_rec[doc_name])
                  end
                end
                break unless continue_loop
              end
          
              # Record rest of queue (if something in the middle failed)
              if not source_operation_data.empty?
                @source.push_queue(queue_name,client_id,[[source_id, source_operation_data]],true)
              end
            end
            # call logoff
            auth_method('logoff')
          end
          
          { "delete_page" => deletes,
            "#{operation}_links" => links,
            "#{operation}_errors" => errors }.each do |doctype,client_docs|
              client_docs.each do |client_id,data|
                client = processed_clients[client_id]
                client.put_data(doctype,data,true) unless data.empty?
              end
          end
            
          if operation == 'create'
            total_creates = {}
            creates.each do |client_id,client_doc|
              next if client_doc.empty?
              client = processed_clients[client_id]
              client.put_data(:cd,client_doc,true)
              client.update_count(:cd_size,client_doc.size)
              total_creates[client.user_id] ||= {}
              total_creates[client.user_id].merge!(client_doc)
            end
            total_creates.each do |user_id, creates_doc|
              creates_source = Source.load(@source.name,
                    {:user_id => user_id,:app_id => APP_NAME})
              creates_source.lock(:md) do |s| 
                s.put_data(:md,creates_doc,true)
                s.update_count(:md_size,creates_doc.size)
              end
            end
          end
            
          if operation == 'delete'
            # Clean up deleted objects from master document and corresponding client document
            total_dels = {}
            objs = {}
            dels.each do |client_id,client_doc|
              next if client_doc.empty?
              client = processed_clients[client_id]         
              client.delete_data(:cd,client_doc)
              client.update_count(:cd_size,-client_doc.size)
              total_dels[client.user_id] ||= {}
              total_dels[client.user_id].merge!(client_doc)
            end
            total_dels.each do |user_id, dels_doc|
              dels_source = Source.load(@source.name,
                    {:user_id => user_id,:app_id => APP_NAME})
              dels_source.lock(:md) do |s| 
                s.delete_data(:md,dels_doc)
                s.update_count(:md_size,-dels_doc.size)
              end
            end
          end
          if operation == 'update'
            errors.each do |client_id, error_doc|
              next if error_doc.empty?
              client = processed_clients[client_id]
              cd = client.get_data(:cd)
              error_doc.each do |key, value|
                client.put_data(:update_rollback,{key => cd[key]},true) if cd[key]
              end
            end
          end   
        end
      end
    end
  end
end