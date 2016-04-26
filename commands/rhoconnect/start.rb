Execute.define_task do
  desc "start [options]", "Start rhoconnect server"
  method_option :port, :aliases => "-p", :type => :numeric, :desc => "Use port (default: #{RHOCONNECT_PORT})"
  method_option :redis, :aliases => "-r", :type => :string, :desc => "Redis server settings: (default: #{REDIS_SERVER_URL})"
  method_option :push_server, :aliases => "-P", :type => :string, :desc => "Push server settings (default: #{PUSH_SERVER_URL})"
  method_option :api_token, :aliases => "-t", :type => :string, :desc => "API token  (default: #{API_TOKEN})"
  method_option :config, :aliases => "-f", :type => :string, :desc => "/path/to/rhoconnect/settings.yml file"
  def start(params = {})
    # if this command called from 'restart', then params not emply
    params = options if params.empty?

    if options[:config] # -f settings.yml
      unless File.exist?(options[:config])
        puts "#{options[:config]}: No such file"
        exit(-1)
      end
    end

    settings = config(options[:config])

    port = (params[:port]) ? params[:port] : URI.parse(settings[:syncserver]).port

    redis_url = (params[:redis]) ? params[:redis] : settings[:redis]
    redis_url = [redis_url] if redis_url.is_a?(String)
    start_list = []
    redis_url.each do |redis_inst|
      start_list << redis_inst unless RedisRunner.running?(redis_inst)
    end
    RedisRunner.startbg(start_list) unless start_list.empty?

    if File.exist?(File.join('settings','settings.yml'))
      # If command running frorm app directory, then do't touch "~/.rhoconnect.yml"
    else
      unless File.exist?(File.join(ENV['HOME'], '.rhoconnect.yml'))
        push_server = (params[:push_server]) ? params[:push_server] : PUSH_SERVER_URL
        token = (params[:api_token]) ? params[:api_token] : API_TOKEN
        options = { :syncserver => "http://localhost:#{port}", :redis => redis_url,
            :push_server => push_server, :api_token => token }
        begin
          require 'securerandom'
          options[:secret] = SecureRandom.hex(64)
        rescue LoadError => e
          puts "Secure random generator is missing"
          puts e.inspect
          exit
        end
        conf_hash = { :development => options, :test => options, :production => options }
        File.open(File.join(ENV['HOME'], '.rhoconnect.yml'), 'w') { |f| f.write(conf_hash.to_yaml) }
      end
    end

    command = "bundle exec rackup -s #{defined?(JRUBY_VERSION) ? 'puma' : 'thin'}"
    rackup_config = settings[:rackup]
    command.sub!(/bundle exec /, '') if(rackup_config != "config.ru")
    # Set environment varialbes: 'API_TOKEN', 'REDIS_URL'
    env = {}
    if params[:api_token]
      env["API_TOKEN"] = params[:api_token]
    end
    if params[:redis]
      env["REDIS_URL"] = params[:redis]
    end

    if jruby?
      puts 'Starting rhoconnect in jruby environment...'
      system(env, "#{command} --port #{port} -P #{rhoconnect_pid} #{rackup_config}")
    elsif windows?
      puts 'Starting rhoconnect...'
      system(env, "#{command} --port #{port} -P #{rhoconnect_pid} #{rackup_config}")
    else
      if dtach_installed?
        puts 'Detach with Ctrl+\  Re-attach with rhoconnect attach'
        sleep 2
        system(env, "dtach -A #{rhoconnect_socket} #{command} --port #{port} -P #{rhoconnect_pid} #{rackup_config}")
      else
        system(env, "#{command} --port #{port} -P #{rhoconnect_pid} #{rackup_config}")
      end
    end
  end
end