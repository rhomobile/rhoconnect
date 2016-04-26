module Rhoconnect
  module Controller
    class Base < Rhoconnect::Server
      def self.rest_path
        "/#{_prefix}/#{_rest_name}"
      end
      
      def self._rest_name
        ret = self.name
        # remove the namespace
        stripped = ret.split("::").last
        ret = stripped unless stripped.nil?
        
        ret.gsub!(/Controller/){}
      end
      
      def self._prefix
        "app/#{Rhoconnect::API_VERSION}"
      end
      
      def self.get(route, params = {}, &block)
        _add_route(route, :get, params, &block)  
      end
      
      def self.post(route, params = {}, &block)
        _add_route(route, :post, params, &block)  
      end
      
      def self.put(route, params = {}, &block)
        _add_route(route, :put, params, &block)  
      end
      
      def self.delete(route, params = {}, &block)
        _add_route(route, :delete, params, &block)  
      end
      
      private
        def self._add_route(route, verb, params, &block)
          resource_route = route
          @default_settings ||= {}
          @default_settings.each do |setting, value|
            params[setting] = value unless params.has_key?(setting)
          end
          api4 "#{self.rest_path}", resource_route, verb, params, &block
        end
    end
    
    # the only purpose of this class is to prepend
    # rest route with /rc/version prefix
    # as opposed to Application-specific resources
    class APIBase < Rhoconnect::Controller::Base
      def self._rest_name
        ret = self.name
        # remove the namespace
        stripped = ret.split("::").last
        ret = stripped unless stripped.nil?
        
        ret.gsub!(/Controller/){}
        ret.downcase 
      end

      private
      def self._prefix
        "rc/#{Rhoconnect::API_VERSION}"
      end
    end
  end
end
