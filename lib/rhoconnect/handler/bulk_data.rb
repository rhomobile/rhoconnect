require 'rhoconnect/handler/helpers'

# Bulk Data extenstion
module Rhoconnect
  module Handler
  	module BulkData
  	  def self.registered(app)
  	  	app.helpers Rhoconnect::Handler::Helpers::BulkData
  	  	# bulk sync request
      	app.post "/bulk_data", \
          	{ :login_required => true,
          	  :client_required => true,
          	  :source_required => false,
          	  :admin_required => false,
              :deprecated_route => {:verb => :get, :url => ['/application/bulk_data', '/api/application/bulk_data']}
          	} do
          content_type :json
          sources_param = params[:sources]
          if sources_param.is_a?String
            sources_param = sources_param.split(',')
          end
          data = do_bulk_data(params[:partition].to_sym,current_client, sources_param)
          data.to_json
        end
      end
  	end
  end
end
