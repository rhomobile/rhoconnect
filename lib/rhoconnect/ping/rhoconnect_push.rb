require 'uri'

module Rhoconnect
  class RhoconnectPush
  	class InvalidPushServer < Exception; end
    class InvalidPushRequest < Exception; end

    def self.ping(params)
      begin
    		settings = get_config(Rhoconnect.base_directory)[Rhoconnect.environment]
        if settings and settings[:push_server]
    			server = URI.join(settings[:push_server], "/messageQueue/#{params['device_pin']}")
		      RestClient.post(
            server.to_s,self.push_message(params),:content_type => :json
          ) do |response, request, result, &block|
            case response.code
            when 200, 204
              response.return!(request, result, &block)
            when 400
              raise InvalidPushRequest.new("Invalid push request.")
            end
          end
		    else
		    	raise InvalidPushServer.new("Missing or invalid `:push_server` in settings/settings.yml.")
        end
	    rescue Exception => error
        log "RhoConnect Push Error: #{error}"
        log error.backtrace.join("\n")
        raise error
      end
    end

    # Generates push package
  	def self.push_message(params)
			data											= {}
			data['collapseId']				= params['badge'].to_i if params['badge']
			data['data']							= {}
			data['data']['alert'] 	  = params['message'] if params['message'] 
			data['data']['sound'] 		= params['sound'] if params['sound']
			data['data']['vibrate']		= params['vibrate'] if params['vibrate']
			data['data']['do_sync'] 	= params['sources'] if params['sources']
			data.to_json
  	end
  end
end