include BenchHelpers
bench_log "Runs admin source methods in batch"

Bench.config do |config|
  config.concurrency ||= 10
  config.iterations  ||= 100
  config.main_marker = 'get_adapter'
  config.user_name = "benchuser"
  config.password = "password"
  config.get_test_server
  config.reset_app
  
  @token = config.get_token
  @save_adapter_url = "my/dynamic/adapter/url"
  config.reset_refresh_time('MockAdapter')
  config.request_logging = false
end


Bench.test do |config,session|
  session.post "save_adapter", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/system/appserver",
    {'X-RhoConnect-API-TOKEN' => @token, :content_type => :json } do
      {:attributes => {:adapter_url => @save_adapter_url}}.to_json
    end
  session.get "get_adapter", "#{config.host}/api/source/get_adapter",
    {'X-RhoConnect-API-TOKEN' => @token, :content_type => :json }
end
