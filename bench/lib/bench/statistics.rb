module Bench
  class Statistics
    include Logging
    
    def initialize(concurrency,iterations,total_time,start_time,end_time,sessions)
      @sessions = sessions
      @rows = {} # row key is result.marker;
      @total_count = 0
      @total_time = total_time
      @start_time = start_time
      @end_time = end_time
      @concurrency,@iterations = concurrency,iterations
    end
    
    def process
      @sessions.each do |session|
        session.results.each do |marker,results|
          results.each do |result|
            @rows[result.marker] ||= {}
            row = @rows[result.marker]
            row[:times] ||= []
            row[:times] << result.time
            row[:min] ||= 0.0
            row[:max] ||= 0.0
            row[:count] ||= 0
            row[:total_time] ||= 0.0
            row[:errors] ||= 0
            row[:verification_errors] ||= 0
            row[:min] = result.time if result.time < row[:min] || row[:min] == 0
            row[:max] = result.time if result.time > row[:max]
            row[:count] += 1.0
            row[:total_time] += result.time            
            row[:errors] += 1 if result.error
            row[:verification_errors] += result.verification_error
            @total_count += 1
          end
        end
      end
      self
    end
    
    def average(row)
      row[:total_time] / row[:count]
    end
    
    def print_stats
      bench_log "Statistics:"
      @rows.each do |marker,row|
        bench_log "Request %-15s: min: %0.4f, max: %0.4f, avg: %0.4f, err: %d, verification err: %d" % [marker, row[:min], row[:max], average(row), row[:errors], row[:verification_errors]]
        row[:times].sort!
        [0.25, 0.50, 0.75, 0.9, 0.95].each do |p|
          index = (p*(row[:times].size - 1) + 1).to_i
          bench_log "\t#{p*100}% <= #{row[:times][index]}"
        end
      end
      bench_log "State of MD        : #{Bench.verify_error == 0 ? true : false}"
      bench_log "Payload (#records) : #{Bench.datasize}" unless Bench.datasize.nil?
      bench_log "Concurrency        : #{@concurrency}"
      bench_log "Iterations         : #{@iterations}"
      bench_log "Total Count        : #{@total_count}"
      bench_log "Total Time         : #{@total_time}"
      bench_log "Av.Time            : #{average(@rows[Bench.main_marker])}" unless Bench.main_marker.nil?
      bench_log "Throughput(req/s)  : #{@total_count / @total_time}"
      bench_log "Throughput(req/min): #{(@total_count / @total_time) * 60.0}"
      self
    end
    
    def save_results
      return self if Bench.result_filename.nil?
      
      res_hash = YAML.load_file(Bench.result_filename) if File.exist?(Bench.result_filename)
      res_hash ||= {}
      res_hash[@concurrency.to_s] = [@total_count/@total_time]
      res_hash[@concurrency.to_s] << average(@rows[Bench.main_marker]) unless Bench.main_marker.nil?
      File.open(Bench.result_filename, 'w' ) do |file|
        file.write res_hash.to_yaml unless res_hash.empty?
      end
      self
    end
    
    # save session times into redis doc
    def save_to_redis
      return self unless Bench.save_to_redis
      
      stats = {}
      throughput_data = {:start_time => @start_time.to_f,
                         :end_time => @end_time.to_f, 
                         :count => @total_count}
      times_data = @rows[Bench.main_marker][:times] unless Bench.main_marker.nil?
      stats[Bench.processor_id] = {:payload => Bench.datasize, :times => times_data.join(',')}
      stats[Bench.processor_id].merge!(throughput_data)
      Bench.set_server_state("bench_statistics_data",stats,true)
      self
    end
  end
end