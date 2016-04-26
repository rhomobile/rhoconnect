module Rhoconnect
  module Handler
  	module PluginCallbacks
  	  class Runner
  	  	attr_accessor :source, :model, :route_handler, :params

  	  	include Rhoconnect::Handler::Helpers::Binding

  	  	def initialize(route_handler, model, params = {})
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app
          raise ArgumentError.new('Invalid plugin_callbacks handler') unless route_handler
          # if handler is not bound - bind it to self
          # normally it should be bound to a Controller's instance
        
          @source = model.source
          @model = model
          @route_handler = bind_handler(:plugin_callback_handler_method, route_handler)  
          @params = params
  	  	end

  	  	def run
  	  	  @route_handler.call
  	  	end
  	  end
  	end
  end
end