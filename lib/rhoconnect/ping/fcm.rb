require 'google/apis/messages'

# https://firebase.google.com/docs/cloud-messaging/auth-server
# https://github.com/oniksfly/google-api-fcm

module Rhoconnect
  class Fcm
    class InvalidProjectId < Exception; end
    class InvalidPackageName < Exception; end
    class FCMPingError < Exception; end

    def self.ping(params)
      begin
        fcm_project_id = Rhoconnect.settings[:fcm_project_id]
        raise InvalidProjectId.new("Missing `:fcm_project_id:` option in settings/settings.yml") unless fcm_project_id

        package_name = Rhoconnect.settings[:package_name]
        raise InvalidPackageName.new("Missing `:package_name:` option in settings/settings.yml") unless package_name
        
        send_ping_to_device(fcm_project_id, package_name, params)
      rescue InvalidProjectId => error
        log error
        log error.backtrace.join("\n")
        raise error
      rescue InvalidPackageName => error
        log error
        log error.backtrace.join("\n")
        raise error
      rescue Exception => error
        log error
        log error.backtrace.join("\n")
        raise error
      end
    end

    def self.send_ping_to_device(project_id,package_name,params)

      scope = Google::Apis::Messages::AUTH_MESSAGES
      authorization = Google::Auth.get_application_default(scope)

      puts '----'
      puts authorization
      
      service = Google::Apis::Messages::MessagesService.new(project_id: project_id)
      service.authorization = authorization
      
      puts params

      puts service.notify(fcm_message(package_name,params))

    end

    def self.fcm_message(package_name,params)
      params.reject! {|k,v| v.nil? || v.length == 0}
      data = {}
      data['do_sync'] = params['sources'] ? params['sources'].join(',') : ''
      data['alert'] = params['message'] if params['message']
      data['vibrate'] = params['vibrate'] if params['vibrate']
      data['sound'] = params['sound'] if params['sound']
      data['phone_id'] = params['phone_id'] if params['phone_id']

      android = {}
      android['collapse_key'] = (rand * 100000000).to_i.to_s
      android['priority'] = 'high'
      android['restricted_package_name'] = package_name
      android['notification'] = {}
      android['notification']['title'] = 'Test message'
      android['notification']['body'] = params['message']

      message = Google::Apis::Messages::Message.new(
        token: params['device_pin'].to_s,
        payload: data,
        android: android
      )
      
      puts '----'
      puts message.message_object.token
      puts data.to_json
      puts '----'
      
      message
    end
  end
end
