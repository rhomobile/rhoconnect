include BenchHelpers
bench_log "Runs simple login,clientcreate,clientregister,sync session and validates response"

Bench.config do |config|
  config.adapter_name ||= "RhoInternalBenchmarkAdapter"
  config.concurrency ||= 1
  config.iterations  ||= 10
  config.datasize ||= 100
  config.main_marker = 'get-cud'
  config.user_name = "benchuser"
  config.password = "password"
  config.get_test_server
  @datasize = Bench.datasize 
  @all_objects = "[{\"version\":3},{\"token\":\"%s\"},{\"count\":%i},{\"progress_count\":0},{\"total_count\":%i},{\"insert\":""}]"
  @ack_token = "[{\"version\":3},{\"token\":\"\"},{\"count\":0},{\"progress_count\":%i},{\"total_count\":%i},{}]"
  @api_token = Bench.get_token
  config.request_logging = false
  
  # if this is not a distributed run - reset the app
  if not Bench.sync_key
    config.reset_app
    @expected = {}
    data_to_create = @datasize
    while (data_to_create > 0) do
      nobjects = data_to_create > 1000 ? 1000 : data_to_create 
      data_page = Bench.get_test_data(nobjects, true)
      config.set_server_state("test_db_storage:application:#{config.user_name}",data_page,true)
      @expected.merge!(data_page)
      data_to_create = data_to_create - nobjects
    end
    # also, simulate load for incremental syncs
    @incr_expected = 130
    incr_data_page = Bench.get_test_data(@incr_expected, true)
    config.set_server_state("test_db_storage:application:mquser",incr_data_page)
    
    @incr_expected = 250
    incr_data_page = Bench.get_test_data(@incr_expected, true)
    config.set_server_state("test_db_storage:application:nquser",incr_data_page)
    
    #exit(1)

    #config.reset_refresh_time('RhoInternalBenchmarkAdapter', 0)
    config.set_simulate_time(Bench.adapter_name, Bench.simtime)
  end
end

Bench.synchronize do |config|
  break unless Bench.sync_key
  while true
    cur_time = Time.now.to_f
    sync_time = Bench.get_server_value(Bench.sync_key).to_f 
    if sync_time > 0.0 and cur_time >= sync_time
      break
    end
    sleep(0.010)
  end
end

Bench.test do |config,session|
  username = SecureRandom.urlsafe_base64(10)
  session.post "clientlogin", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/app/login", :content_type => :json do
    {:login => username, :password => config.password}.to_json
  end
  session.post "clientcreate", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/clients"
  client_id = JSON.parse(session.last_result.body)['client']['client_id']
  session.client_id = client_id

  session.post "clientregister", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/clients/#{session.client_id}/register",
    {:content_type => :json} do
      {:device_type => "Apple", :device_pin => 'somepin123', :device_port => "device_port_111",
        :phone_id => 'unique_phone_id'}.to_json
    end
    
  pagesize = @datasize
  pagesize = @datasize/10 if @datasize > 1000
  session.get "get-cud",
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{Bench.adapter_name}",
    {'X-RhoConnect-CLIENT-ID' => session.client_id} do
      {'p_size' => pagesize}
    end
  token = session.last_result.headers[:x_rhoconnect_page_token]
  while (token and token != '') do
    session.get "ack-cud",
      "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{Bench.adapter_name}",
      {'X-RhoConnect-CLIENT-ID' => session.client_id} do
        {'token' => token,
          'p_size' => pagesize}
      end
    token = session.last_result.headers[:x_rhoconnect_page_token]
    session.last_result.verify_code(200)
  end
  
  # now , create 2 records and then, delete them
  # we also generate 2 random records for CUD calls
  expected_for_cud = Bench.generate_fake_data(2, false)
  session.post "create-object",
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{Bench.adapter_name}", 
    {:content_type => :json, 'X-RhoConnect-CLIENT-ID' => session.client_id} do
      {:create => expected_for_cud}.to_json
    end  
  session.last_result.verify_code(200)
  
  obj_to_delete = expected_for_cud.keys[0]
  session.delete "delete_object",
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{Bench.adapter_name}/#{obj_to_delete}",
    {'X-RhoConnect-CLIENT-ID' => session.client_id}
  session.last_result.verify_code(200)
  
  obj_to_delete = expected_for_cud.keys[1]
  session.post "push_deletes", 
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{Bench.adapter_name}/push_deletes",
      {'X-RhoConnect-API-TOKEN' => config.token, :content_type => :json} do
    {:user_id => username,
      :rebuild_md => false,
      :objects => [obj_to_delete]
    }.to_json
  end
  session.last_result.verify_code(200)
end
