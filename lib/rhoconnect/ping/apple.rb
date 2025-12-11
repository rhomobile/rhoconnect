require 'socket'
require 'openssl'
module Rhoconnect
  class Apple
    def self.ping(params)
      #log '$$$ ping params = '+params.to_s
      settings = get_config(Rhoconnect.base_directory)[Rhoconnect.environment]
      #puts '$$$ settings = '+settings.to_s
      cert_file = nil # File.join(Rhoconnect.base_directory,settings[:iphonecertfile])
      passphrase = nil
      device_app_id = params[:device_app_id]
      if device_app_id != nil
         if  settings[:iphonecertificates] != nil
            if  settings[:iphonecertificates][device_app_id] != nil
                cert_file = settings[:iphonecertificates][device_app_id][:iphonecertfile]
                passphrase = settings[:iphonecertificates][device_app_id][:iphonepassphrase]
            end
         end
      end
      if cert_file == nil
          cert_file = settings[:iphonecertfile]
      end
      if passphrase == nil
          passphrase = settings[:iphonepassphrase]
      end

      #puts '$$$ cert_file = '+cert_file.to_s
      cert_file = File.join(Rhoconnect.base_directory,cert_file)

      cert = File.read(cert_file) if File.exist?(cert_file)

    	host = settings[:iphoneserver]
    	port = settings[:iphoneport]
      if(cert and host and port)
        begin
          ssl_ctx = OpenSSL::SSL::SSLContext.new
      		ssl_ctx.key = OpenSSL::PKey::RSA.new(cert, passphrase.to_s)
      		ssl_ctx.cert = OpenSSL::X509::Certificate.new(cert)

      		socket = TCPSocket.new(host, port)
      		ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_ctx)
      		ssl_socket.sync = true
      		ssl_socket.connect

      		res = ssl_socket.write(apn_message(params))
      		ssl_socket.close
      		socket.close
    	  rescue SocketError => error
    		  log "Error while sending ping: #{error}"
    		  raise error
        end
		  else
        log "Invalid APNS settings: ping is ignored."
        log "cert_file: #{cert_file}, host: #{host}, port: #{port}"
      end
    end

    # Generates APNS package
  	def self.apn_message(params)
  		data = {}
  		data['aps'] = {}
  		data['aps']['alert'] = params['message'] if params['message']
  		data['aps']['badge'] = params['badge'].to_i if params['badge']
  		data['aps']['sound'] = params['sound'] if params['sound']
  		data['aps']['vibrate'] = params['vibrate'] if params['vibrate']
  		data['do_sync'] = params['sources'] if params['sources']
  		json = data.to_json
  		"\0\0 #{[params['device_pin'].delete(' ')].pack('H*')}\0#{json.length.chr}#{json}"
  	end
  end

  # Deprecated - use Apple instead
  class Iphone < Apple
    def self.ping(params)
      log "DEPRECATION WARNING: 'iphone' is a deprecated device_type, use 'apple' instead"
      super(params)
    end
  end
end
