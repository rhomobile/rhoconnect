module Rhoconnect
	module Model
		module Helpers
			module FindDuplicatesOnUpdate

				def self.included(base)
					base.extend Rhoconnect::Model::Helpers::FindDuplicatesOnUpdate::ClassMethods
				end

        def find_duplicates_on_update(options, invalid_meta, operation, operation_data, client_ids)
	        invalid_meta ||= {}
	        # processed_ids = {}
	        processed_objs = {}
	        operation_data.each_with_index do |client_operation_data,index|
	          client_id = client_ids[index]
	          client_operation_data.each do |source_operation_entry|
	            source_id = source_operation_entry[0]
	            list_of_objs = source_operation_entry[1]
	            list_of_objs.each_with_index do |obj_entry, objindex|
	              key = obj_entry[0]
	              objvalue = obj_entry[1]

	              processed_objs[source_id] ||= {}
	              processed_source_objs = processed_objs[source_id]
	              obj_not_a_duplicate = true
	              if processed_source_objs.has_key? key
	                processed_records = processed_source_objs[key]
	                processed_records.each do |processed_record|
	                  master_obj = processed_record[:value]
	                  # master_client_id = processed_record[:client_id]
	                  master_queue_index = processed_record[:queue_index].to_i
	                  master_obj_index = processed_record[:index].to_i

	                  if master_obj == objvalue
	                    obj_not_a_duplicate = false
                      if options[:raise_error]
	                		  invalid_meta[index] ||= {}
	                		  invalid_meta[index][source_id] ||= {}
	                		  invalid_meta[index][source_id][objindex] ||= {}
	                		  invalid_meta[index][source_id][objindex][:error] = "Error during #{operation}: object conflict detected"
	                	  else
		                    invalid_meta[index] ||= {}
		                    invalid_meta[index][source_id] ||= {}
		                    invalid_meta[index][source_id][objindex] ||= {}
		                    invalid_meta[index][source_id][objindex][:duplicate_of] = true

		                    invalid_meta[master_queue_index] ||= {}
		                    invalid_meta[master_queue_index][source_id] ||= {}
		                    invalid_meta[master_queue_index][source_id][master_obj_index] ||= {}
		                    invalid_meta[master_queue_index][source_id][master_obj_index][:duplicates] ||= []
		                    invalid_meta[master_queue_index][source_id][master_obj_index][:duplicates] <<  {:client_id => client_id, :key => key, :value => objvalue}
                      end
	                    break
	                  end
	                end
	              end
	              # objects are not equal - add to already processed
	              if obj_not_a_duplicate
	                processed_source_objs[key] ||= []
	                processed_source_objs[key] << {:value => objvalue, :client_id => client_id, :queue_index => index, :index => objindex}
	              end
	            end
	          end
	        end
          if options[:handler] and invalid_meta.size > 0
	        	proc = bind_handler :find_duplicates_on_update, options[:handler]
            invalid_meta = proc.call options, invalid_meta, operation, operation_data, client_ids
          end
	        invalid_meta
        end

	     	# methods that needs to be 'extended', not 'included'
        module ClassMethods
		    	def install_find_duplicates_on_update(options)
		    		options ||= {}
		    		options[:update] = true
		      	@validators ||= {}
		      	@validators[:find_duplicates_on_update] = options
		      	options
		    	end
        end
			end
		end
	end
end