module Bench
  module Utils
    include Logging
    
    def sort_natural_order(nocase=false)
      proc do |str|
        i = true
        str = str.upcase if nocase
        str.gsub(/\s+/, '').split(/(\d+)/).map {|x| (i = !i) ? x.to_i : x}
      end
    end
    
    def compare(name1,s1,name2,s2)
      r1 = diff([],name1,s1,name2,s2)
      r2 = diff([],name2,s2,name1,s1)
      r1.size > r2.size ? r1 : r2
    end
    
    def diff(res,lname,lvalue,rname,rvalue,path=[])

      return res if lvalue == rvalue
      
      if lvalue.is_a?(Array) and rvalue
        lvalue.each_index do |index| 
          p = Array.new(path)
          p << index
          diff(res,lname,lvalue[index],rname,rvalue.at(index),p)
        end                
      elsif lvalue.is_a?(Hash) and rvalue
        lvalue.each do |key,value| 
          p = Array.new(path)
          p << key
          diff(res,lname,value,rname,rvalue[key],p)
        end
      else            
        res << {:path=>path,lname=>lvalue,rname=>rvalue}
      end
      
      res 
    end
    
    def compare_and_log(expected,actual,caller)
      if expected != actual
        bench_log "#{log_prefix} Verify error at: " + caller
        bench_log "#{log_prefix} Message diff: "
        compare(:expected,expected,:actual,actual).each do |diff|
          bench_log "#{log_prefix} Path: #{diff[:path].join('/')}"
          bench_log "#{log_prefix} Expected: #{diff[:expected].inspect}"
          bench_log "#{log_prefix} Actual: #{diff[:actual].inspect}"
        end
        1
      else
        0
      end
    end
    
    def create_subdir(dir)
      begin
        if File.directory? dir
          dir += '_' + Time.now.strftime("%Y_%m_%d_%H_%M_%S")
        end
        Dir.mkdir(dir)
        dir
      rescue
      end
    end
    
    def load_settings(file)
      begin
        return YAML.load_file(file)
      rescue Exception => e
        puts "Error opening settings file #{file}: #{e}."
        puts e.backtrace.join("\n")
        raise e
      end
    end
    
    def start_rhoconnect_app(options)
      options[:app_started] = false
      path = options[:start_server] || '.'
      if not File.exist?(File.join(path,'settings','settings.yml'))
        puts " Invalid Rhoconnect app path '#{path}' - no app files can be found there"
        return false
      end
      settings = load_settings(File.join(path,'settings','settings.yml'))
      app_url = settings[:production][:syncserver].gsub(/\/$/,'')
      
      uri = URI.parse(app_url)
      port = (uri.port and uri.port != 80) ? ":"+uri.port.to_s : "" 
      options[:server_url] = "#{uri.scheme}://#{uri.host}#{port}"
      
      already_running = check_rc_service(options[:server_url])
      if already_running
        puts " Another Rhoconnect Application is already running at '#{options[:server_url]}'"
        return false
      end
      
      # start the app now
      puts "Starting up the Rhoconnect Application at #{options[:server_url]}"
      current_dir = Dir.pwd
      Dir.chdir(path)
      exit_code = system("bundle exec rake rhoconnect:startbg")
      sleep 2
      Dir.chdir(current_dir)
      
      options[:app_started] = check_rc_service(options[:server_url])
    end
    
    def stop_rhoconnect_app(options)
      return unless options[:app_started] == true
      
      path = options[:start_server] || '.'
      if not File.exist?(File.join(path,'settings','settings.yml'))
        puts " Invalid Rhoconnect app path '#{path}' - no app files can be found there"
        return
      end
      puts "Stopping the Rhoconnect Application at #{options[:server_url]}"
      current_dir = Dir.pwd
      Dir.chdir(path)
      system("bundle exec rake rhoconnect:stop")
      sleep 1
      Dir.chdir(current_dir)
    end
    
    # check_rc_service
    # Makes an HTTP request to check that the rhoconnect app is up and running
    def check_rc_service(server_name)
      success = false
      begin
        request = Net::HTTP.get_response(URI.parse("#{server_name}/console"))
        if request.code == '200'
          success = true
        end
      rescue
      end
      success
    end #check_rc_service
    
    # prepare bench results
    def prepare_bench_results_dirs(dir)
      start_dir = Dir.pwd
      Dir.chdir dir
      
      # create result directory structure
      ['bench_results'].each do |dir|
        next if dir.nil?
        created_dir = Bench.create_subdir dir
        Dir.chdir created_dir
      end
      result_dir = Dir.pwd
      ['raw_data'].each do |dir|
        Bench.create_subdir dir
      end
      
      Dir.chdir start_dir
      result_dir
    end
    
    def prepare_bench_results_meta(dir, title, x_keys)
      title ||= "Results"
      
      start_dir = Dir.pwd
      Dir.chdir(dir)
      
      # 3) create meta.yml file
      meta_hash = {:x_keys => {}, :metrics => {}, :label => title}
      counter = 0
      x_keys = x_keys.sort_by(&Bench.sort_natural_order)
      x_keys.each do |x_key|
        meta_hash[:x_keys][x_key] = counter
        counter += 1
      end

      meta_hash[:metrics] = {'Throughput' => 0, 'Av.Time' => 1}

      File.open(File.join(dir,'raw_data','meta.yml'), 'w') do |file|
        file.write meta_hash.to_yaml unless meta_hash.empty?
      end
      
      Dir.chdir start_dir
      true
    end
  end
end