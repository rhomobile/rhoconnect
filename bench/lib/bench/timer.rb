module Bench
  module Timer
    def time
      start = Time.now
      yield
      end_time = Time.now   
      end_time.to_f - start.to_f
    end
    
    def times
      start = Time.now
      yield
      end_time = Time.now   
      [end_time.to_f - start.to_f, start, end_time]
    end
  end
end