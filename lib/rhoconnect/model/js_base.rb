module Rhoconnect
  module Model
    class JsBase < Rhoconnect::Model::Base
      class << self
        attr_accessor :js_method_list,:actual_name
      end
      attr_accessor :result

      def method_missing(method_name,*args)
        obj = Object.const_get(self.class.to_s)
        if obj.js_method_list.include? method_name.to_s
          self.class.package_and_publish(self,method_name,current_user,args)
        else
          log "METHOD #{method_name} NOT DEFINED IN JS MODEL #{self.class.to_s}"
          return "#{method_name} method not defined for #{self.class.to_s}"
        end
      end

      def self.register_models(models)
        app = App.load(APP_NAME)
        models.each do |key,val|
          a_name = key
          klassified = key.classify
          unless Object.const_defined?(klassified)
            klass = Object.const_set(klassified, Class.new(Rhoconnect::Model::JsBase))
            klass.js_method_list = val
            klass.actual_name = a_name
          end
          source = Source.load(klassified,{:app_id=>APP_NAME,:user_id=>'*'})
          unless source
            sconfig = Rhoconnect.source_config(klassified)
            Source.create(sconfig.merge!(:name => klassified),{:app_id => APP_NAME})
            app.sources << klassified
          end
        end
      end

      def login
        rho_methods('login')
      end

      def query(params=nil)
        @result = rho_methods('query',params)
      end

      def search(params=nil)
        rho_methods('search',params)
      end

      def create(create_hash)
       rho_methods('create',create_hash)
      end

      def update(update_hash)
        rho_methods('update',update_hash)
      end

      def delete(delete_hash)
        rho_methods('delete',delete_hash)
      end

      def logoff
        rho_methods('logoff')
      end

      def store_blob(obj,field_name,blob)
        blob[:path] = blob[:tempfile].path
        rho_methods('storeBlob',blob)
      end

      def self.partition_name(user_id)
        class_rho_methods('partitionName',{:user_id => user_id})
      end

      def self.class_rho_methods(name,args=nil)
        if has_method? name
          package_and_publish(self,name,nil,args)
        else
          send(name,args)
        end
      end

      def self.has_method?(name)
        self.js_method_list.include? name
      end

      def rho_methods(name,args=nil)
        if self.class.has_method? name
          self.class.package_and_publish(self,name,self.current_user,args)
        else
          send(name,args)
        end
      end

      def self.package_and_publish(caller,method_name,user,args=nil)
        json = {
           :klss   => self.actual_name,
           :function => method_name,
           :args  => args,
           :route => 'request'
         }
         json[:user] = user.login if user
         NodeChannel.publish_channel_and_wait(json,caller)
      end
    end
  end
end

class String
  def classify
    result = self.split("_").inject("") do |res,index|
      res += index.capitalize
      res
    end
    result
  end
end
