require 'thor'

module Bench
  class Cli < Thor
    include Logging
    desc "start path/to/bench/script", "Start performance test"
    def start(script,login,password='',*params)
      server = params[0] unless params[0].nil?
      server ||= 'default'
      if server != 'default'
        Bench.base_url = server
      end
      Bench.result_filename = params[1] unless params[1].nil?
      Bench.concurrency = params[2].to_i unless params[2].nil?
      Bench.iterations = params[3].to_i unless params[3].nil?
      Bench.datasize = params[4].to_i unless params[4].nil?
      Bench.simtime = params[5].to_i unless params[5].nil?
      Bench.adapter_name = params[6] unless params[6].nil?
      Bench.admin_login = login
      Bench.admin_password = password
      load(script)
      Statistics.new(Bench.concurrency,Bench.iterations,
        Bench.total_time,Bench.start_time,Bench.end_time,Bench.sessions).process.print_stats.save_results
      bench_log "Bench completed..."
      #Bench.reset_app
    end
  end
  
  class DistributedCli < Thor
    include Logging
    desc "start path/to/bench/script", "Start performance test"
    def start(script,login,password='',*params)
      server = params[0] unless params[0].nil?
      server ||= 'default'
      if server != 'default'
        Bench.base_url = server
      end
      Bench.sync_key = params[1] unless params[1].nil?
      Bench.save_to_redis = true
      Bench.processor_id = "#{Socket.gethostname}_#{Process.pid}"
      Bench.concurrency = params[2].to_i unless params[2].nil?
      Bench.iterations = params[3].to_i unless params[3].nil?
      Bench.datasize = params[4].to_i unless params[4].nil?
      Bench.simtime = params[5].to_i unless params[5].nil?
      Bench.adapter_name = params[6] unless params[6].nil?
      Bench.admin_login = login
      Bench.admin_password = password
      load(script)
      Statistics.new(Bench.concurrency,Bench.iterations,
        Bench.total_time,Bench.start_time,Bench.end_time,Bench.sessions).process.print_stats.save_to_redis
      bench_log "Bench completed..."
    end
  end
end