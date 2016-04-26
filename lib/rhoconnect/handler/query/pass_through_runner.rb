module Rhoconnect
  module Handler
    module Query
      class PassThroughRunner < Rhoconnect::Handler::Query::Runner
        def run
          token = params[:token]
          ack_token(token) if token
          res = []
          query_result = engine.do_sync
          res = send_new_page(query_result)
          format_result(res[0],res[1],res[2],res[3])
        end
        
        def send_new_page(data)
          data ||= {}
          data.each_key do |object_id| 
            data[object_id].each { |attrib,value| data[object_id][attrib] = '' if value.nil? }
          end
          token = ''
          compute_errors_page
          res = build_page do |r|
            r['insert'] = data
            r['metadata'] = compute_metadata
          end
          if res['insert']
            token = @client.compute_token(:page_token)
          else
            _delete_errors_page 
          end    
          [token,0,data.size,res]
        end
      end
    end
  end
end