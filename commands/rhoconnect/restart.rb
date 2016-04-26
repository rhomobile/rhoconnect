Execute.define_task do
  desc "restart [options]", "Alias for `rhoconnect stop; rhoconnect start`"
  method_option :port, :aliases => "-p", :type => :numeric, :desc => "Use port (default: #{RHOCONNECT_PORT})"
  method_option :redis, :aliases => "-r", :type => :string, :desc => "Redis server settings: (default: #{REDIS_SERVER_URL})"
  method_option :push_server, :aliases => "-P", :type => :string, :desc => "Push server settings (default: #{PUSH_SERVER_URL})"
  method_option :api_token, :aliases => "-t", :type => :string, :desc => "API token  (default: #{API_TOKEN})"
  method_option :config, :aliases => "-f", :type => :string, :desc => "/path/to/rhoconnect/settings.yml file"  
  def restart
    puts "Stop rhoconnect server ..."
    stop
    puts "Start rhoconnect server ..."
    start options
  end
end