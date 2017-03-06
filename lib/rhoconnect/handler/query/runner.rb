module Rhoconnect
  # implementation classes
  module Handler
    module Query
      class Runner
      	attr_accessor :source,:client,:p_size,:engine,:params

        def initialize(model,client,route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_CLIENT) unless client
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app

     	    @source,@client,@p_size = model.source,client,params[:p_size] ? params[:p_size].to_i : 500
     	    @client.last_sync = Time.now if @client
     	    @params = params
     	    @engine = Rhoconnect::Handler::Query::Engine.new(model, route_handler, @params)
        end

        def run
          res = []
          token = params[:token]
          if not ack_token(token)
            res = resend_page(token)
          else
            query_result = @engine.do_sync
            res = send_new_page
          end
          format_result(res[0],res[1],res[2],res[3])
        end

        # Resend token for a client, also sends exceptions
        def resend_page(token=nil)
          token,progress_count,total_count,res = '',0,0,{}
          schema_page = @client.get_value(:schema_page)
          if schema_page
            res = {'schema-changed' => 'true'}
          else  
            res = build_page do |r|
              r['insert'] = @client.get_data(:page)
              r['delete'] = @client.get_data(:delete_page)
              r['links'] = @client.get_data(:create_links_page)
              r['metadata'] = @client.get_value(:metadata_page)
              progress_count = 0
              total_count = @client.get_value(:total_count_page).to_i
            end
          end
          token = @client.get_value(:page_token)
          [token,progress_count,total_count,res]
        end

      	def ack_token(token)
          stored_token = @client.get_value(:page_token)
          if stored_token 
            if token and stored_token == token
              @client.put_value(:page_token,nil)
              @client.flush_data(:schema_page)
              @client.flush_data(:metadata_page)
              @client.flush_data(:create_links_page)
              @client.flush_data(:page)
              @client.flush_data(:delete_page)
              _delete_errors_page
              return true
            else
                if token == nil
                    # client lost state - may be previous connection was failed etc.
                    # we ned reinit connection
                    puts "$$$ ERROR: receive NIL token => reset saved session connection. client["+@client.to_s+"] stored token["+stored_token.to_s+"]"
                    @client.put_value(:page_token,nil)
                    _delete_errors_page
                    return true
                end
            end
          else
            return true    
          end    
          false
        end

        def format_result(token,progress_count,total_count,res)
          count = 0
          count += res['insert'].length if res['insert']
          count += res['delete'].length if res['delete']
          [ {'version'=>Rhoconnect::SYNC_VERSION},
            {'token'=>(token ? token : '')},
            {'count'=>count},
            {'progress_count'=>progress_count},
            {'total_count'=>total_count},
            res ]
        end

        def build_page
          res = {}
          yield res
          res.reject! {|key,value| value.nil? or value.empty?}
          res.merge!(_send_errors)
          res
        end

        def send_new_page
          token,progress_count,total_count,res = '',0,0,{}
          if schema_changed?
            _expire_bulk_data
            token = @client.compute_token(:page_token)
            res = {'schema-changed' => 'true'}
          else  
            compute_errors_page
            res = build_page do |r|
              total_count,r['insert'],r['delete'] = compute_page
              r['links'] = compute_links_page
              r['metadata'] = compute_metadata
            end
            if res['insert'] or res['delete'] or res['links']
              token = @client.compute_token(:page_token)
            else
              _delete_errors_page 
            end
          end
          # TODO: progress count can not be computed properly
          # without comparing what has actually changes
          # so we need to obsolete it in the future versions
          progress_count = 0
          [token,progress_count,total_count,res]
        end

        def send_new_page_bruteforce
          token,progress_count,total_count,res = '',0,0,{}
          if schema_changed?
            _expire_bulk_data
            token = @client.compute_token(:page_token)
            res = {'schema-changed' => 'true'}
          else  
            compute_errors_page
            res = build_page do |r|
              total_count,r['insert'],r['delete'] = compute_page_bruteforce
              r['links'] = compute_links_page
              r['metadata'] = compute_metadata
            end
            if res['insert'] or res['delete'] or res['links']
              token = @client.compute_token(:page_token)
            else
              _delete_errors_page 
            end
          end
          # TODO: progress count can not be computed properly
          # without comparing what has actually changes
          # so we need to obsolete it in the future versions
          progress_count = 0
          [token,progress_count,total_count,res]
        end

        # Checks if schema changed
        def schema_changed?
          if engine.model.respond_to?(:schema)
            schema_sha1 = @source.get_value(:schema_sha1)
            if @client.get_value(:schema_sha1).nil?
              @client.put_value(:schema_sha1,schema_sha1)
              return false
            elsif @client.get_value(:schema_sha1) == schema_sha1
              return false
            end
            @client.put_value(:schema_sha1,schema_sha1)
            @client.put_value(:schema_page,schema_sha1)
            return true
          else
            return false
          end
        end

        # Computes the metadata sha1 and returns metadata if client's sha1 doesn't 
        # match source's sha1
        def compute_metadata
          metadata_sha1,metadata = @source.lock(:metadata) do |s|
            [s.get_value(:metadata_sha1),s.get_value(:metadata)]
          end
          return if @client.get_value(:metadata_sha1) == metadata_sha1
          @client.put_value(:metadata_sha1,metadata_sha1)
          @client.put_value(:metadata_page,metadata)
          metadata
        end
        
        
        # Computes diffs between master doc and client doc, trims it to page size, 
        # stores page, and returns page as hash  
        def compute_page
          inserts_elements_map,deletes_elements_map,total_count = @source.lock(:md) do |s| 
            inserts_elements_map = @client.get_diff_data(:cd,s.docname(:md),@p_size)
            total_count = s.get_value(:md_size).to_i
            deletes_elements_map = s.get_diff_data(:md,@client.docname(:cd),@p_size)
            [inserts_elements_map,deletes_elements_map,total_count]
          end
          # until sync is not done - set cd_size to 0
          # once there are no changes, then, set cd_size to md_size
          cd_size = inserts_elements_map.size > 0 ? 0 : total_count
          @client.put_value(:cd_size, cd_size)
          
          # now, find the exact changes
          inserts,deletes = Store.get_inserts_deletes(inserts_elements_map,deletes_elements_map)
          
          @client.put_data(:page,inserts)
          @client.put_data(:delete_page,deletes,true)
          @client.put_value(:total_count_page,total_count)
          @client.update_elements(:cd,inserts_elements_map,deletes_elements_map)
          
          [total_count,inserts,deletes]
        end
        
        # Computes diffs between master doc and client doc, trims it to page size, 
        # stores page, and returns page as hash  
        def compute_page_bruteforce
          inserts_elements_map,deletes_elements_map,total_count = @source.lock(:md) do |s| 
            inserts_elements_map,deletes_elements_map = @client.get_diff_data_bruteforce(:cd,s.docname(:md),@p_size)
            total_count = s.get_value(:md_size).to_i
            [inserts_elements_map,deletes_elements_map,total_count]
          end
          # until sync is not done - set cd_size to 0
          # once there are no changes, then, set cd_size to md_size
          cd_size = inserts_elements_map.size > 0 ? 0 : total_count
          @client.put_value(:cd_size, cd_size)
          
          # now, find the exact changes
          inserts,deletes = Store.get_inserts_deletes(inserts_elements_map,deletes_elements_map)
          
          @client.put_data(:page,inserts)
          @client.put_data(:delete_page,deletes,true)
          @client.put_value(:total_count_page,total_count)
          @client.update_elements(:cd,inserts_elements_map,deletes_elements_map)
          
          [total_count,inserts,deletes]
        end

        # Computes errors for client and stores a copy as errors page
        def compute_errors_page
          ['create','update','delete'].each do |operation|
            @client.lock("#{operation}_errors") do |c| 
              c.rename("#{operation}_errors","#{operation}_errors_page")
            end
          end
          @client.lock("update_rollback") do |c|
            c.rename("update_rollback","update_rollback_page")
          end
        end
        
        # Computes create links for a client and stores a copy as links page
        def compute_links_page
          @client.lock(:create_links) do |c| 
            c.rename(:create_links,:create_links_page)
            c.get_data(:create_links_page)
          end
        end

        private
        def _delete_errors_page
          ['create','update','delete'].each do |operation|
            @client.flush_data("#{operation}_errors_page")
          end
          @client.flush_data("update_rollback_page")
        end

        def _send_errors
          res = {}
          ['create','update','delete'].each do |operation|
            res["#{operation}-error"] = @client.get_data("#{operation}_errors_page")
          end
          res["source-error"] = @source.lock(:errors) { |s| s.get_data(:errors) }
          res["update-rollback"] = @client.get_data(:update_rollback_page)
          res.reject! {|key,value| value.nil? or value.empty?}
          res
        end

        # expires the bulk data for the client
        def _expire_bulk_data
          [:user,:app].each do |partition|
            Rhoconnect.expire_bulk_data(@client.user_id,partition)
          end
        end
      end
    end
  end
end