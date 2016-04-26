module Rhoconnect
  module Handler
  	module PluginCallbacks
  	  module ExecuteMethods
  	  	def execute_push_objects_handler(route_handler)
  	  	  source = _load_source
          @model = Rhoconnect::Model::Base.create(source)
          @handler = Rhoconnect::Handler::PluginCallbacks::Runner.new(route_handler, @model, params)
          @handler.run
          'done'
  	  	end
  	  	# same functionality in push_deletes - only differs in controller's route implementation
  	  	alias_method :execute_push_deletes_handler, :execute_push_objects_handler

  	  	# the following methods are not exposed as handlers - instead they're used directly
  	  	# TODO: potentially deprecate them - push_* are fast enough already
  	  	def do_fast_insert
          source = _load_source
          timeout = params[:timeout] || 10
          raise_on_expire = params[:raise_on_expire] || false
          new_objs = params[:data]
      	  source.lock(:md,timeout,raise_on_expire) do |s|
        	diff_count = new_objs.size
        	source.put_data(:md, new_objs, true)
        	source.update_count(:md_size,diff_count)
      	  end
      	  source.announce_changes
          'done'
        end

        def do_fast_update
          source = _load_source
          timeout = params[:timeout] || 10
          raise_on_expire = params[:raise_on_expire] || false
          remove_hash = params[:delete_data]
          new_hash = params[:data]
          
      	  if ((remove_hash and remove_hash.size > 0) or (new_hash and new_hash.size > 0))
    		    source.lock(:md,timeout,raise_on_expire) do |s|
    		      # get the objects from DB, remove prev attr data, add new attr data
    		      update_keys = Set.new
    		      update_keys += Set.new(remove_hash.keys) if remove_hash
    		      update_keys += Set.new(new_hash.keys) if new_hash
    		      objs_to_update = source.get_objects(:md, update_keys.to_a) || {}
    		      diff_count = -objs_to_update.size
    		      # remove old values from DB
    		      source.delete_data(:md, objs_to_update)
    		      # update data
    		      remove_hash.each do |key, obj|
    		        next unless objs_to_update[key]
    		        obj.each do |attrib, value|
    		          objs_to_update[key].delete(attrib)
    		          objs_to_update.delete(key) if objs_to_update[key].empty?
    		        end
    		      end if remove_hash
    		      new_hash.each do |key, obj|
    		        objs_to_update[key] ||= {}
    		        objs_to_update[key].merge!(obj)
    		      end if new_hash
    		      # store new data into DB
    		      source.put_data(:md, objs_to_update, true)
    		      diff_count += objs_to_update.size
    		      source.update_count(:md_size,diff_count)
    		    end
    		    source.announce_changes
        	end
          'done'  
        end

        def do_fast_delete
          source = _load_source
          timeout = params[:timeout] || 10
          raise_on_expire = params[:raise_on_expire] || false

          delete_objs = params[:data]
	        source.lock(:md,timeout,raise_on_expire) do |s|
	          diff_count = -delete_objs.size
	          source.delete_data(:md, delete_objs)
	          source.update_count(:md_size,diff_count)
	        end
	        source.announce_changes
          'done'
        end

        private
        def _load_source
          source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
          # if source does not exist create one for dynamic adapter
          unless source
            sconfig = Rhoconnect.source_config(params[:source_id])
            source = Source.create(sconfig.merge!({:name => params[:source_id]}),{:user_id => params[:user_id], :app_id => APP_NAME})
            current_app.sources << source.name
          end
          source  
        end
  	  end
  	end
  end
end