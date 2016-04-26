require 'set'

module Bench
  class Result
    attr_accessor :last_response,:time,:marker,:url,:verb,:error,:verification_error
    include Logging
    include Utils
    
    def initialize(marker,verb,url,thread_id,iteration)
      @marker,@verb,@url,@thread_id,@iteration = marker,verb,url,thread_id,iteration
      @verification_error = 0
      @time = 0
    end
    
    def code
      @last_response.code
    end
    
    def body
      @last_response.to_s
    end
    
    def cookies
      @last_response.cookies
    end
    
    def headers
      @last_response.headers
    end
    
    def verify_body(expected)
      expected,actual = JSON.parse(expected),JSON.parse(@last_response.to_s)    
      @verification_error += compare_and_log(expected,actual,caller(1)[0].to_s)
    end
    
    def verify_code(expected)
      if expected != @last_response.code
        bench_log "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        bench_log "#{log_prefix} Code diff: "
        bench_log "#{log_prefix} expected: #{expected.inspect}"
        bench_log "#{log_prefix} but got:  #{@last_response.code}"
        @verification_error += 1
      end
    end
    
    def verify_headers
      
    end
  end
end