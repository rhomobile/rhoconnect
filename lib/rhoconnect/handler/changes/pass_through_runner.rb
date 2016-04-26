module Rhoconnect
  module Handler
  	module Changes
  	  class PassThroughRunner < Rhoconnect::Handler::Changes::Runner
    		def run
    		  @engine.do_pass_through_cud
    		end
  	  end
    end
  end
end