module Rhoconnect
  module Handler
    module Query
      module ExecuteMethods
        def execute_query_handler(route_handler)
          content_type :json
          @handler = nil
          if not current_source.is_pass_through?
            @handler = Rhoconnect::Handler::Query::Runner.new(@model, current_client, route_handler, params)
          else
            @handler = Rhoconnect::Handler::Query::PassThroughRunner.new(@model, current_client, route_handler, params)
          end
          formatted_res = @handler.run
          response.headers[Rhoconnect::PAGE_TOKEN_HEADER] = formatted_res[1]['token']
          response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER] = formatted_res[2]['count'].to_s
          response.body = formatted_res.to_json     
        end
      end
    end
  end
end