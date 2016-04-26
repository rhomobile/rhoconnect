module Rhoconnect
  module Handler
    module Search
      module ExecuteMethods
        def execute_search_handler(route_handler)
          content_type :json
          return [].to_json unless params[:sources]
          res = []
          params[:sources].each do |source_params|
            s = Source.load(source_params['name'],{:app_id => current_client.app_id,
              :user_id => current_client.user_id})
            current_client.source_name = source_params['name']
            @model = Rhoconnect::Model::Base.create(s)

            params[:token] = source_params['token'] if source_params['token']
            if not s.is_pass_through?
              @handler = Rhoconnect::Handler::Search::Runner.new(@model, current_client, route_handler, params)
            else
              @handler = Rhoconnect::Handler::Search::PassThroughRunner.new(@model, current_client, route_handler, params)
            end
            @model = @handler.engine.model
            search_res = @handler.run
            res << search_res if search_res
          end
          response.headers[Rhoconnect::PAGE_TOKEN_HEADER] = res[0][1]['token'] if res[0][1] and res[0][1]['token']
          response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER] = res[0][3]['count'].to_s if res[0][3] and res[0][3]['count']
          res.to_json     
        end
      end
    end
  end
end