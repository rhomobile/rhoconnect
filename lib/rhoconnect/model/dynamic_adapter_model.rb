require 'json'
require 'rest_client'
require 'uri'

module Rhoconnect
  module Model
    class DynamicAdapterModel < Rhoconnect::Model::Base
      attr_accessor :uri, :partition
      
      def initialize(source, partition=nil, uri=nil)
        @source = source
        @uri = uri || Rhoconnect.appserver
        @partition = partition || @source.user_id
        
        if @uri
          @uri = URI.parse(@uri)
          user = @uri.user
          @uri.user = nil
          @uri = @uri.to_s 
        end
        
        @token = Rhoconnect.api_token || user   
        raise Exception.new("Please provide a :token or set it in uri") unless @token
        super(source)
      end
      
      def self.authenticate(login,password)
        hsh = {:login => login, :password => password, :api_token => Rhoconnect.api_token}.to_json
        headers = {:content_type => :json, :accept => :json}
        RestClient.post "#{Rhoconnect.appserver}/rhoconnect/authenticate", hsh, headers
      end
      
      def query(params=nil)
        @result={}
        @result = JSON.parse(send_objects('query',@source.name, @partition, params))
      end
      
      def create(create_hash)
        send_objects('create',@source.name, @partition, create_hash)
      end
      
      def update(update_hash)
        send_objects('update',@source.name, @partition, update_hash)
      end
      
      def delete(delete_hash)
        send_objects('delete',@source.name, @partition, delete_hash)
      end
      
      #protected
      
      def validate_args(action, source_name, partition, obj = {}) # :nodoc:
        raise Exception.new("Please set uri in your settings or through console") unless @uri
        raise ArgumentError.new("Missing object id for #{obj.inspect}") if ['update','delete'].include? action and not obj.has_key?('id')
        raise ArgumentError.new("Missing source_name.") if source_name.empty?
        #raise ArgumentError.new("Missing partition for #{model}.") unless partition or partition.blank?
      end

      def send_objects(action, source_name, partition, obj = {}) # :nodoc:
        validate_args(action, source_name, partition, obj)
        process(:post, "/rhoconnect/#{action}", 
          {
            :resource => source_name,
            :partition => partition,
            :attributes => obj 
          }
        )
      end
          
      def resource(path) # :nodoc:
        RestClient::Resource.new(@uri)[path]
      end

      def process(method, path, payload = nil) # :nodoc:
        headers = api_headers
        payload  = payload.merge!(:api_token => @token).to_json
        args     = [method, payload, headers].compact
        response = resource(path).send(*args)
        response
      end

      def api_headers   # :nodoc:
        {
          :content_type => :json, 
          :accept => :json
        }
      end
    end
  end
end