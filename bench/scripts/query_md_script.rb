include BenchHelpers
bench_log "Run sync session, forces source adapter query on every sync request"

@datasize = 100
@expected = Bench.get_test_data(@datasize)
@all_objects = "[{\"version\":3},{\"token\":\"%s\"},{\"count\":%i},{\"progress_count\":0},{\"total_count\":%i},{\"insert\":""}]"
@ack_token = "[{\"version\":3},{\"token\":\"\"},{\"count\":0},{\"progress_count\":%i},{\"total_count\":%i},{}]"

Bench.config do |config|
  config.concurrency = 5
  config.iterations  = 2
  config.user_name = "benchuser"
  config.password = "password"
  config.adapter_name = 'MockAdapter'  
  config.get_test_server
  config.reset_app
  config.set_server_state("test_db_storage:application:#{config.user_name}",@expected)
  config.reset_refresh_time('MockAdapter',0)
end

Bench.test do |config,session|
  sleep rand(10)
  session.post "clientlogin", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/app/login", :content_type => :json do
    {:login => config.user_name, :password => config.password}.to_json
  end    
  
  sleep rand(10)
  session.post "clientcreate", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/clients"
  client_id = JSON.parse(session.last_result.body)['client']['client_id']
  session.get "get-cud",
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{config.adapter_name}",
    {'X-RhoConnect-CLIENT-ID' => client_id} do
      {'p_size' => @datasize}
    end

  sleep rand(10)
  token = JSON.parse(session.last_result.body)[1]['token']
  session.last_result.verify_body([{:version => 3},{:token => token}, 
    {:count => @datasize},{:progress_count => 0},{:total_count => @datasize}, 
    {:insert => @expected}].to_json)
      
  sleep rand(10)
  session.get "ack-cud",
    "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{config.adapter_name}",
    {'X-RhoConnect-CLIENT-ID' => client_id} do
      {'token' => token}
    end
  session.last_result.verify_code(200)
  session.last_result.verify_body([{:version => 3},{:token => ''},{:count => 0},
    {:progress_count => 0},{:total_count => @datasize},{}].to_json)
end  
