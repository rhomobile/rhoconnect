module Bench
  module Logging
    attr_accessor :request_logging
    
    def log_prefix
      "[T:%03d|I:%03d]" % [@thread_id.to_i, @iteration.to_i]
    end
    
    def bench_log(msg)
      Rhoconnect.log msg
    end
  end
end