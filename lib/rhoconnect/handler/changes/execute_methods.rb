# this is the actual pseudo-middleware handler for Create/Update/Delete
module Rhoconnect
  module Handler
    module Changes
      module ExecuteMethods
        # combined CUD filter (aka 'queue_updates')
        def execute_cud_handler(route_handler)
          _extract_cud_params
          _run_cud_handler(route_handler)
        end

        # individual filters
        def execute_create_handler(route_handler)
          _extract_cud_params
          _run_cud_handler(route_handler, 'create')
        end

        def execute_update_handler(route_handler)
          _extract_cud_params
          # merge specific 'update' params
          begin
            if params["update"]
              cud = params["update"]
              params.delete("update")
              params.merge!("update" => {params[:id] => cud})
            end     
          rescue JSON::ParserError => jpe
            log jpe.message + jpe.backtrace.join("\n")
            throw :halt, [500, "Server error while processing client data"]
          rescue Exception => e
            log e.message + e.backtrace.join("\n")
            throw :halt, [500, "Internal server error"]
          end

          _run_cud_handler(route_handler, 'update')
        end

        def execute_delete_handler(route_handler)
          begin
            obj = current_client.get_object(:cd, params[:id])
            params.merge!("delete" => { params[:id] => obj } )     
          rescue JSON::ParserError => jpe
            log jpe.message + jpe.backtrace.join("\n")
            throw :halt, [500, "Server error while processing client data"]
          rescue Exception => e
            log e.message + e.backtrace.join("\n")
            throw :halt, [500, "Internal server error"]
          end

          _run_cud_handler(route_handler, 'delete')
        end

        # encapsulate common code
        def _run_cud_handler(route_handler, operations = ['create', 'update', 'delete'])
          @handler = nil
          if operations.is_a?String
            operations = [operations]
          end
          if not current_source.is_pass_through?
            @handler = Rhoconnect::Handler::Changes::Runner.new(operations, @model, current_client, route_handler, params)
          else
            @handler = Rhoconnect::Handler::Changes::PassThroughRunner.new(operations, @model, current_client, route_handler, params)
          end
          catch_all do
            @handler.run
          end
          status 200
        end

        def _extract_cud_params
          begin
            if params["cud"]
              cud = JSON.parse(params["cud"])
              params.delete("cud")
              params.merge!(cud)
            end     
          rescue JSON::ParserError => jpe
            log jpe.message + jpe.backtrace.join("\n")
            throw :halt, [500, "Server error while processing client data"]
          rescue Exception => e
            log e.message + e.backtrace.join("\n")
            throw :halt, [500, "Internal server error"]
          end
        end
      end
    end
  end
end