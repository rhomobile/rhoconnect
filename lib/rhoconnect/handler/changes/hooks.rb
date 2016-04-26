module Rhoconnect
	module Handler
		module Changes
			module Hooks
				def self.handler_installed(controller, rc_handler, verb, route_url, options)
	  			queue_key = "#{verb}:#{route_url}"
	  			# QUEUE key is unique per route
	  			# standard routes - should go to the standard :create, :update, :delete queues
	  			case queue_key
	  			when "post:/", "put:/:id", "delete:/id"
	  				queue_key = nil
	  			end

	  			queue_names = []
	  			case rc_handler.to_sym
	  			when :cud
	  				queue_names << (queue_key ? "create:#{queue_key}" : "create")
	  				queue_names << (queue_key ? "update:#{queue_key}" : "update")
	  				queue_names << (queue_key ? "delete:#{queue_key}" : "delete")
	  			when :create
	  				queue_names << (queue_key ? "create:#{queue_key}" : "create")
	  			when :update
	  				queue_names << (queue_key ? "update:#{queue_key}" : "update")
	  			when :delete
	  				queue_names << (queue_key ? "delete:#{queue_key}" : "delete")
	  			else
	  				return true
	  			end

	  			Source.define_valid_queues(queue_names)
	  			options[:add_parameter] = {:queue_key => queue_key} if queue_key
	  		end
			end
		end
	end
end