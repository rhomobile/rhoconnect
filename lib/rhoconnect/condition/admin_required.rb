module Rhoconnect
  module Condition
    module AdminRequired
      def self.extended(base)
        base.include_admin_required_condition
      end

      def include_admin_required_condition
        set(:admin_required) do |value|
          condition do
            if value
              begin
                api_token = ApiToken.load(env[API_TOKEN_HEADER])
                api_token = ApiToken.load(params[:api_token]) unless api_token
                raise Rhoconnect::ApiException.new(422, "No API token provided") unless api_token
                raise Rhoconnect::ApiException.new(422, "Invalid/missing API user") unless api_token.user and api_token.user.admin == 1
                env[Rhoconnect::CURRENT_USER] = api_token.user
              rescue Rhoconnect::ApiException => ae
                throw :halt, [422, {'Content-Type' => 'text/plain'}, ae.message]
              end
            end
          end
        end
      end
    end
  end
end
