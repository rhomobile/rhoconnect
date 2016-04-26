module Rhoconnect
  module Controller
    module JsBaseHelpers
      def query_finish(return_value)
        @model.result = return_value
      end
    end

    class JsBase < Rhoconnect::Controller::Base
      # Add helpers for deprecated routes
      Rhoconnect::DefaultServer.helpers Rhoconnect::Controller::JsBaseHelpers

      helpers Rhoconnect::Controller::JsBaseHelpers
      #register Rhoconnect::Handler::PluginCallbacks

      # source name is available inherently from controller
      before do
        params[:source_name] = self.class._rest_name
        params[:source_id] = self.class._rest_name
      end

      def self.register_routes(json)
        Rhoconnect::Model::JsBase.register_models(json['models'])
        json['result'].each do |key,val|
          controller_name = "#{key}Controller"
          next if Object.const_defined?(controller_name)
          if controller_name == 'ApplicationController'
            klass = Object.const_set(controller_name, Class.new(Rhoconnect::Controller::JsAppBase))
          else
            klass = Object.const_set(controller_name, Class.new(Rhoconnect::Controller::JsBase))
          end
          Rhoconnect.add_to_url_map(klass)
          process_defaults(klass,val['defaults'])
          process_routes(klass,val['routes'])

          # add PluginCallback routes (but only for Adapter Controllers)
          unless controller_name == "ApplicationController"
            klass.register Rhoconnect::Handler::PluginCallbacks
          end
        end
      end

      private

      def self.process_defaults(klass,defaults)
        defaults.each do |default|
          default.each do |key,val|
            klass.send(:set_default,key.to_sym,val)
          end
        end
      end

      def self.process_routes(klass,routes)
        routes.each do |r|
          opts = {}
          s_route = r.split('_rjs_')
          verb = s_route[0]
          action = s_route[2]
          opts = hshify(s_route[3]) if s_route[3]
          block = js_block(r)
          case opts[:rc_handler]
          when 'query'
            block = js_block(r,:query_finish)
          end
          klass.send(verb,action,opts,&block)
        end
      end

      def self.hshify(str)
        JSON.parse(str, :symbolize_names => true)
      end

      def self.js_block(key,finish_block=nil)
        Proc.new do
          json = {
             :url   => key,
             :args  => params,
             :model => under_score(params[:source_name]),
             :route => 'request'
          }
          json[:user] = @model.current_user.login if @model
          return_value = NodeChannel.publish_channel_and_wait(json,@model || self)
          if finish_block
            self.send(finish_block, return_value)
          else
            return_value
          end
        end
      end

      def self._prefix
        "app/#{Rhoconnect::API_VERSION}"
      end

    end
    class JsAppBase < Rhoconnect::Controller::JsBase
      set_default :admin_required, false
      set_default :login_required, false
      set_default :source_required, false
      set_default :client_required, false

      def self.inherited(subclass)
        subclass.set_default :admin_required, false
        subclass.set_default :login_required, false
        subclass.set_default :source_required, false
        subclass.set_default :client_required, false
        super
      end

      register Rhoconnect::Handler::Search
      register Rhoconnect::Handler::BulkData

      # main app controller
      def self._rest_name
        "app"
      end

      private
      def self._prefix
        "rc/#{Rhoconnect::API_VERSION}"
      end
    end
  end
end