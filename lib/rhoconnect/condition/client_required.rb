require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Condition
    # Sinatra condition
    module ClientRequired
      def self.extended(base)
        base.include_client_required_condition
      end

      def include_client_required_condition
        include ClientRequiredHelpers
        set(:client_required) do |value|
          condition do
            if value
              catch_all do
                client = extract_current_client
                # client should be valid here
                raise ArgumentError.new(UNKNOWN_CLIENT) unless client
                env[CURRENT_CLIENT] = client
              end
            end
          end
        end
      end
    end

    module ClientRequiredHelpers
      # helper method
      def extract_current_client
        client = nil
        # TODO: This is removed when V3 is deprecated
        if params["cud"]
          cud_client_id = JSON.parse(params["cud"])["client_id"]
          params.merge!(:client_id => cud_client_id) if cud_client_id
        end
        client_id = @env[Rhoconnect::CLIENT_ID_HEADER]
        client_id = params[:client_id] unless client_id
        if client_id
          client = Client.load(client_id.to_s,
                               params[:source_name] ? {:source_name => params[:source_name]} : {:source_name => '*'})
          if client and current_user and client.user_id != current_user.login
            client.switch_user(current_user.login)
          end
        end
        client
      end
    end
  end
end