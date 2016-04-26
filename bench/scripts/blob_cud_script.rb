require 'rhoconnect'

include BenchHelpers
bench_log "Simulate creating multiple blob objects"

Bench.config do |config|
  config.concurrency = 5 # users
  config.iterations  = 2 # devices
  config.user_name = "benchuser"
  config.password  = "password"
  config.adapter_name = 'BlobAdapter'
  config.get_test_server("blobapp")
  config.reset_app
  config.reset_refresh_time('BlobAdapter',0)
  config.set_server_state("test_db_storage:application:#{config.user_name}",{})

  @create_objects = []
  @create_count = 5

  @users = Bench.get_bench_users(config.concurrency)
  @users.each { |u| Bench.create_user(u.user_name, u.password) }

  config.concurrency.times do |i|
    @create_objects << []
    config.iterations.times do
      @create_objects[i] << Bench.get_test_data(@create_count, true, true)
    end
  end
  
  @datasize = config.iterations * @create_count # calculate datasize per user
  @expected_md = {}
  @create_objects.each do |iteration|
    iteration.each do |objects|
      @expected_md.merge!(objects)
    end
  end
end

Bench.test do |config, session|
  sleep rand(10) 
  user = @users[session.thread_id]
  session.post "clientlogin", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/app/login", :content_type => :json do
    {:login => user.user_name, :password => user.password}.to_json
  end

  sleep rand(10)
  session.post "clientcreate", "#{config.host}/rc/#{Rhoconnect::API_VERSION}/clients"
  session.client_id = JSON.parse(session.last_result.body)['client']['client_id']
  create_objs = @create_objects[session.thread_id][session.iteration]
  body = { :cud =>  {:source_name => 'BlobAdapter',
    :blob_fields => ['img_file-rhoblob'], :create => create_objs}.to_json 
  }
  session.post "create-object", "#{config.host}/app/#{Rhoconnect::API_VERSION}/#{config.adapter_name}",
    {:content_type => :json, 'X-RhoConnect-CLIENT-ID' => session.client_id} do
      body.merge!(Bench.get_image_data(create_objs)) # Add images to miltipart post
    end
  session.last_result.verify_code(200)

  sleep rand(10)
  bench_log "#{session.log_prefix} User \"#{user.user_name}\": Loop to get available objects ..."
  count = get_all_objects(current_line, config, session, @expected_md, create_objs)
  bench_log "#{session.log_prefix} User \"#{user.user_name}\": Got #{count} available objects ..."
end

Bench.verify do |config,sessions|
  sessions.each do |session|
    user = @users[session.thread_id]
    bench_log "#{session.log_prefix} User \"#{user.user_name}\": Loop to load all objects..."
    session.results['create-object'][0].verification_error += 
      verify_numbers(
        @datasize,get_all_objects(
          caller(0)[0].to_s,config,session,@expected_md,nil,0),session,current_line)
    bench_log "#{session.log_prefix} User \"#{user.user_name}\": Loaded all objects..."
  end

  sessions.each do |session|
    actual = config.get_server_state(
      client_docname( @users[session.thread_id].user_name, # config.user_name,
                     session.client_id,
                     'BlobAdapter',:cd))
    actual.keys.each do |k|
      session.results['create-object'][0].verification_error +=
        Bench.compare_and_log(@expected_md[k], actual[k], current_line)
    end
  end
  
  master_doc = {}
  @users.each do |user| 
    user_doc = config.get_server_state(
      source_docname(user.user_name, 'BlobAdapter',:md))
    master_doc.merge!(user_doc)
  end
  Bench.verify_error = Bench.compare_and_log(@expected_md, master_doc, current_line)

  @users.each do |user|
    Bench.delete_user(user.user_name)
  end
end