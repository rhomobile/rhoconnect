module Rhoconnect
  module Handler
  	module Helpers
  	  module SourceJob
        # Enqueue a job for the source based on job type
      	def async(job_type,queue_name,params=nil)
        	  Rhoconnect::SourceJob.queue = queue_name
            Resque.enqueue(Rhoconnect::SourceJob,job_type,@source.id,
                           @source.app_id,@source.user_id,params)
      	end
      end
    end
  end
end
