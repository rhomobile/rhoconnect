module Rhoconnect
  # implementation classes
  module Handler
    module Search
      class Runner
        attr_accessor :source,:client,:p_size,:model,:engine,:params

        def initialize(model,client,route_handler, params = {})
          raise ArgumentError.new(UNKNOWN_CLIENT) unless client
          raise ArgumentError.new(UNKNOWN_SOURCE) unless (model and model.source)
          raise ArgumentError.new('Invalid app for source') unless model.source.app

          @source,@client,@p_size = model.source,client,params[:p_size] ? params[:p_size].to_i : 500
          @model = model
          @client.last_sync = Time.now if @client
          @params = params
          @engine = Rhoconnect::Handler::Search::Engine.new(@model, @client, route_handler, @params)
        end

        def run
          if params
            return _resend_search_result if params[:token] and params[:resend]
            if params[:token] and !_ack_search(params[:token]) 
              formatted_result = _format_search_result
              _delete_search
              return formatted_result
            end
          end
          _do_search
        end

        private
        def _do_search
          # call model search unless client is sending token for ack
          res = @engine.do_search if params.nil? or !params[:token]
          res,diffsize =  _compute_search 
          formatted_res = _format_search_result(res,diffsize)      
          _delete_search if diffsize == 0
          formatted_res
        end
        
        # Computes search result, updates md for source and cd for client with the result
        def _compute_search
          cd_inserts_elements_map = @client.get_diff_data(:cd,@client.docname(:search),@p_size)
          
          @client.update_elements(:cd, cd_inserts_elements_map, {})
          @client.update_count(:cd_size,cd_inserts_elements_map.size)
          # remove previous search page and build new one
          @client.flush_data(:search_page)
          @client.update_elements(:search_page,cd_inserts_elements_map,{})
          client_res = @client.get_data(:search_page)
          
          @source.lock(:md) do |s|
            md_inserts_elements_map = s.get_diff_data(:md,@client.docname(:cd))
            s.update_elements(:md, md_inserts_elements_map, {})
            s.update_count(:md_size,md_inserts_elements_map.size)
          end
          
          [client_res,client_res.size]
        end
        
        def _resend_search_result
          res = @client.get_data(:search_page)
           _format_search_result(res,res.size)
        end
        
        def _ack_search(search_token)
          if @client.get_value(:search_token) != search_token
            _delete_search
            @client.put_data(:search_errors,
              {'search-error'=>{'message'=>'Search error - invalid token'}}
            )
            return false
          end
          true
        end
        
        def _delete_search
          [:search, :search_page, :search_token, :search_errors].each do |search_doc|
         	  @client.flush_data(search_doc)
         	end
        end
        
        def _format_search_result(res={},diffsize=nil)
          error = @client.get_data(:search_errors)
          if not error.empty?
            [ {'version'=>Rhoconnect::SYNC_VERSION},
              {'source'=>@source.name},
              {'search-error'=>error} ]
          else  
            search_token = @client.get_value(:search_token)
            search_token ||= ''
            return [] if res.empty?
            [ {'version'=>Rhoconnect::SYNC_VERSION},
              {'token' => search_token},
              {'source'=>@source.name},
              {'count'=>res.size},
              {'insert'=>res} ]
           end
        end
      end
    end
  end
end