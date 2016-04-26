module Bench
  class DistrRunner
  
    attr_accessor :start_time, :end_time, :clients_group
    attr_accessor :total_count, :times_count, :times_sum
    
    def initialize(clientgroup)
      @clients_group = clientgroup
    end
    
    def run(server, sync_key, payload, concurrency, niterations, result_filename=nil, sim_time = 0, bench_adapter_name = "RhoInternalBenchmarkAdapter")
      # 1) Extract server name
      server ||= 'default'
      if server != 'default'
        Bench.base_url = server
      end
      
      # 2) Simulate the payload
      Bench.datasize = payload.to_i
      expected_data = Bench.get_test_data(Bench.datasize)
      Bench.concurrency = concurrency.to_i
      Bench.iterations = niterations.to_i
      Bench.adapter_name = bench_adapter_name
      # 3) extract result filename
      Bench.result_filename = result_filename

      # 4) Set up the server
      begin 
        Bench.admin_login = 'rhoadmin'
        Bench.admin_password = ''
        Bench.get_test_server
        Bench.reset_app
        Bench.user_name = "benchuser"
        Bench.password = "password"
        Bench.set_server_state("test_db_storage:application:#{Bench.user_name}",expected_data)
        Bench.reset_refresh_time(Bench.adapter_name, 0)
        Bench.set_simulate_time(Bench.adapter_name, sim_time)

        #6) set the sync key
        @start_time = Time.now + 10.0
        Bench.set_server_state(sync_key, @start_time.to_f.to_s)
        puts "Sync Key #{sync_key} is set to #{@start_time} - waiting for clients now!!!"

        #7) Start-up all clients
        command="cd /opt/rhoconnect/bin; ruby run_client_benchmark #{server} #{sync_key} #{niterations} 1 #{Bench.datasize} #{Bench.adapter_name} 1>/dev/null"
        ec2_clients = clients_group.client_instances[0,concurrency]
        Bench::AWSUtils.run_stack_ssh_command(ec2_clients, command)
      
        #8) Wait until the command is done and save all data to the disk
        sleep(1)
        @total_count = 0
        @start_time = 0.0
        @end_time = 0.0
        @times_sum = 0.0
        @times_count = 0
        process_results
        save_results

        #9) Clean-up the db
        Bench.reset_app
      rescue Exception => e
        puts "Distributed Bench Runner ERROR !!!"
        puts e.message
        puts e.backtrace.join("\n")
      end
    end
    
    def process_results
      finished_data = Bench.get_server_state("bench_statistics_data")
      finished_data.each do |session,session_data|
        puts "Client data for #{session} : startTime (#{session_data['start_time']}), endTime (#{session_data['end_time']})"
        @total_count += session_data['count'].to_i
        @start_time = session_data['start_time'].to_f unless @start_time > 0.0 and session_data['start_time'].to_f >= @start_time
        @end_time = session_data['end_time'].to_f unless session_data['end_time'].to_f <= @end_time
        if not session_data['times'].nil?
          times_data = session_data['times'].split(',')
          @times_count += times_data.size
          times_data.each do |timevalue|
            @times_sum += timevalue.to_f
          end
        end
      end
    end

    def average_time
      @times_count > 0 ? @times_sum/@times_count : 0.0
    end

    def save_results
      return if Bench.result_filename.nil?

      res_hash = YAML.load_file(Bench.result_filename) if File.exist?(Bench.result_filename)
      res_hash ||= {}
      puts "Overall results are : startTime (#{@start_time.to_s}), endTime (#{@end_time.to_s}), count (#{@total_count.to_s}), payload (#{Bench.datasize}), concurrency (#{Bench.concurrency})"
      res_hash[Bench.concurrency.to_s] = (@end_time > 0.0 and @start_time > 0.0) ? [@total_count/(@end_time - @start_time)] : [0.0]
      res_hash[Bench.concurrency.to_s] << average_time
      File.open(Bench.result_filename, 'w' ) do |file|
        file.write res_hash.to_yaml unless res_hash.empty?
      end
    end
  
  end
end