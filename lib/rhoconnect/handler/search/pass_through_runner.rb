module Rhoconnect
  module Handler
    module Search
      # this class just overrides one method
      class PassThroughRunner < Rhoconnect::Handler::Search::Runner
        private
        def _do_search
          # call model search unless client is sending token for ack
          res = @engine.do_search if params.nil? or !params[:token]
          res,diffsize =  [res,res.size]
          formatted_res = _format_search_result(res,diffsize)      
          _delete_search if diffsize == 0
          formatted_res
        end
      end
    end
  end
end