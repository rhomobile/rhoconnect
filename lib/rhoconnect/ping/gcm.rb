require 'rest_client'

module Rhoconnect
  class Gcm
    class InvalidApiKey < Exception; end
    class GCMPingError < Exception; end

    def self.ping(params)
      begin
        gcm_api_key = Rhoconnect.settings[:gcm_api_key]
        raise InvalidApiKey.new("Missing `:gcm_api_key:` option in settings/settings.yml") unless gcm_api_key

        send_ping_to_device(gcm_api_key, params)
      rescue InvalidApiKey => error
        log error
        log error.backtrace.join("\n")
        raise error
      rescue Exception => error
        log error
        log error.backtrace.join("\n")
        raise error
      end
    end

    def self.send_ping_to_device(api_key,params)
      RestClient.post(
        'https://android.googleapis.com/gcm/send', gcm_message(params).to_json,
        :authorization => "key=#{api_key}",
        :content_type => :json
      ) do |response, request, result, &block|
        # return exceptions based on response code & body
        case response.code
        when 200
          if response.body =~ /^Error=(.*)$/
            raise GCMPingError.new("GCM ping error: #{$1 || ''}")
          end
          response.return!(request, result, &block)
        when 401, 403
          raise InvalidApiKey.new("Invalid GCM api key. Obtain new api key from GCM service.")
        end
      end
    end

    def self.gcm_message(params)
      params.reject! {|k,v| v.nil? || v.length == 0}
      data = {}
      data['registration_ids'] = [params['device_pin'].to_s]
      data['collapse_key'] = (rand * 100000000).to_i.to_s
      data['data'] = {}
      data['data']['do_sync'] = params['sources'] ? params['sources'].join(',') : ''
      data['data']['alert'] = params['message'] if params['message']
      data['data']['vibrate'] = params['vibrate'] if params['vibrate']
      data['data']['sound'] = params['sound'] if params['sound']
      data['data']['phone_id'] = params['phone_id'] if params['phone_id']
      data
    end
  end
end