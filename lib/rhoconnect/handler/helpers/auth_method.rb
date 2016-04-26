module Rhoconnect
  module Handler
    module Helpers
      module AuthMethod
        def auth_method(operation,client_id=-1)
          edockey = nil
          docobj = nil
          if client_id == -1 
            edockey = :errors
            docobj = @source
          else
            edockey = :search_errors
            docobj = Client.load(client_id,{:source_name => @source.name})
          end 
          begin
            docobj.flush_data(edockey) if operation == 'login'
            @model.send operation
          rescue Exception => e
            log "Model raised #{operation} exception: #{e}"
            log e.backtrace.join("\n")
            docobj.put_data(edockey,{"#{operation}-error"=>{'message'=>e.message}},true)
            return false
          end
          true
        end
      end
    end
  end
end