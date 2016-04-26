require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Condition
    module SourceRequired
      def self.extended(base)
        base.include_source_required_condition
      end

      def include_source_required_condition
        set(:source_required) do |value|
          condition do
            if value
              catch_all do
                source = nil
                user = current_user
                # TODO - this should be removed when old routes are removed
                if params["cud"]
                  cud_source_name = JSON.parse(params["cud"])["source_name"]
                  params.merge!({:source_name => cud_source_name}) if cud_source_name
                end
                # resource name is the source
                if params[:source_name] and user
                  source = Source.load(params[:source_name],
                    {:user_id => user.login,:app_id => APP_NAME})

                  # if source does not exist create one for dynamic adapter
                  unless source
                    sconfig = Rhoconnect.source_config(params[:source_name])
                    source = Source.create(sconfig.merge!({:name => params[:source_name]}),{:user_id => user.login, :app_id => APP_NAME})
                    current_app.sources << source.name
                  end
                else
                  Rhoconnect.log "ERROR: Can't load source, no source_name provided.\n"
                  raise ArgumentError.new(UNKNOWN_SOURCE)
                end
                #puts "loaded source: #{source.inspect}"
                env[CURRENT_SOURCE] = source
                # by default - all routes should have an access to the model
                # if the route require source
                @model = Rhoconnect::Model::Base.create(source)
              end
            end
          end
        end
      end
    end
  end
end
