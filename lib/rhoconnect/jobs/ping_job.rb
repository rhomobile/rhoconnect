require 'rhoconnect/ping'

module Rhoconnect
  module PingJob
    @queue = :ping

    # Enqueue a ping job
    def self.enqueue(params)
      Resque.enqueue(PingJob, params)
    end
    
    # Perform a ping for all clients registered to a user
    def self.perform(params)
      device_pins = []
      phone_ids = []
      user_ids = params['user_id']
      user_ids = [user_ids] unless user_ids.is_a? Array
      errors = []
      user_ids.each do |user|
        user_errors = ping_by_user user, params, device_pins, phone_ids
        errors = errors + user_errors if user_errors
      end
      if errors.size != 0
        joined_err = errors.join '\n'
        raise joined_err
      end
    end
    
    def self.ping_by_user(user_id, params, device_pins, phone_ids)
      # all errors are recorded here
      errors = []
      user = User.load(user_id)
      clients = user.clients if user
      if clients
        clients.members.reverse_each do |client_id|
          client = Client.load(client_id,{:source_name => '*'})
          params.merge!(
            'device_port' => client.device_port,
            'device_pin' => client.device_pin,
            'phone_id' => client.phone_id,
            'device_app_id' => client.device_app_id,
            'device_app_version' => client.device_app_version
          )
          send_push = false
          if client.device_type and client.device_type.size > 0
            if client.phone_id and client.phone_id.size > 0
              combined_phone_id = client.phone_id
              if client.device_app_id and client.device_app_id.size > 0
                  combined_phone_id = combined_phone_id + client.device_app_id
              end
              unless phone_ids.include? combined_phone_id
                phone_ids << combined_phone_id
                send_push = true
              end
            elsif client.device_pin and client.device_pin.size > 0
              unless device_pins.include? client.device_pin   
                device_pins << client.device_pin
                send_push = true
              end
            else
              log "Skipping ping for non-registered client_id '#{client_id}'..."
              next
            end
            if send_push
              type = client.device_push_type || client.device_type
              klass = nil
              begin
                klass = Object.const_get(camelize(type.downcase))
              rescue Exception => e
                log "Dropping ping request for unsupported platform '#{type}'"
              end
              if klass
                params['vibrate'] = params['vibrate'].to_s
                begin
                  klass.ping(params) 
                rescue Exception => e
                  errors << e
                end
              end
            else
              log "Dropping ping request for client_id '#{client_id}' because it's already in user's device pin or phone_id list."
            end
          else
            log "Skipping ping for non-registered client_id '#{client_id}'..."
          end
        end
      else
        log "Skipping ping for unknown user '#{user_id}' or '#{user_id}' has no registered clients..."
      end
      errors
    end
  end
end
