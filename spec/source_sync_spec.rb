require File.join(File.dirname(__FILE__),'spec_helper')

describe "SourceSync" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    @model = Rhoconnect::Model::Base.create(@s)
  end

  let(:mock_schema) { {"property" => { "name" => "string", "brand" => "string" }, "version" => "1.0"} }

  describe "SourceSync query methods" do
    before (:each) do
      rh = lambda { @model.query(params[:query])}
      @model = Rhoconnect::Model::Base.create(@s)
      @ssq = Rhoconnect::Handler::Query::Engine.new(@model, rh, {})
    end

    it "should create Rhoconnect::Handler::Query::Engine" do
      @ssq.model.is_a?(SampleAdapter).should == true
    end

    it "should fail to create Rhoconnect::Handler::Query::Engine with InvalidArgumentError without source" do
      lambda { Rhoconnect::Handler::Query::Engine.new(nil, nil, {}) }.should raise_error(ArgumentError, 'Unknown source')
    end

    it "should fail to create Rhoconnect::Handler::Query::Engine with InvalidArgumentError without proc handler" do
      lambda { Rhoconnect::Handler::Query::Engine.new(@model, nil) }.should raise_error(ArgumentError, 'Invalid sync handler')
    end

    it "should raise LoginException if login fails" do
      msg = "Error logging in"
      @u.login = nil
      @ssq.should_receive(:log).with("Model raised login exception: #{msg}")
      @ssq.should_receive(:log).with(anything)
      @ssq.do_sync
      verify_doc_result(@s, :errors => {'login-error'=>{'message'=>msg}})
    end

    it "should raise LogoffException if logoff fails" do
      msg = "Error logging off"
      @ssq.should_receive(:log).with("Model raised logoff exception: #{msg}")
      @ssq.should_receive(:log).with(anything)
      set_test_data('test_db_storage',{},msg,'logoff error')
      @ssq.do_sync
      verify_doc_result(@s, :errors => {'logoff-error'=>{'message'=>msg}})
    end

    it "should hold on read on subsequent call of process if default poll interval is not exprired" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => expected)
      @ssq.do_sync
      set_state('test_db_storage' => {'2'=>@product2})
      @ssq.do_sync
      verify_doc_result(@s, :md => expected)
    end

    it "should read on every subsequent call of process if poll interval is set to 0" do
      expected = {'2'=>@product2}
      @s.poll_interval = 0
      set_state('test_db_storage' => {'1'=>@product1})
      @ssq.do_sync
      set_state('test_db_storage' => expected)
      @ssq.do_sync
      verify_doc_result(@s, :md => expected)
    end

    it "should never call read on any call of process if poll interval is set to -1" do
      @s.poll_interval = -1
      set_state('test_db_storage' => {'1'=>@product1})
      @ssq.do_sync
      verify_doc_result(@s, :md => {})
    end


    it "should process model metadata" do
      mock_metadata_method([SampleAdapter, SimpleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ssq.do_sync
        verify_doc_result(@s, {:md => expected,
              :metadata => "{\"foo\":\"bar\"}",
              :metadata_sha1 => "a5e744d0164540d33b1d7ea616c28f2fa97e754a"})
      end
    end

    it "should process model schema" do
      mock_schema_method([SampleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ssq.do_sync
        verify_doc_result(@s, :md => expected)
        JSON.parse(@s.get_value(:schema)).should == mock_schema
        @s.get_value(:schema_sha1).should == get_sha1(mock_schema['version'])
      end
    end

    it "should raise exception if model schema has no version key/value pair" do
      mock_schema_no_version_method([SampleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ssq.do_sync
        errors = {}
        @s.lock(:errors) { errors = @s.get_data(:errors) }
        errors.empty?().should == false
        errors["query-error"]["message"].should == "Mandatory version key is not defined in model schema method"
      end
    end

    it "should process model with stash" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @ssq.params[:query] = {'stash_result' => true}
      @ssq.do_sync
      #@ssq.model.should_receive(:stash_result).once
      verify_doc_result(@s, {:md => expected,
                          :md_size => expected.size.to_s})
    end

    it "should process model with pass_through set" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @s.pass_through = 'true'
      @ssq.do_sync.should == expected
      verify_doc_result(@s, {:md => {},
                              :md_size => nil})
      @s.pass_through = nil
    end

    it "should call methods in model" do
      mock_metadata_method([SampleAdapter, SimpleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        metadata = "{\"foo\":\"bar\"}"
        @ssq.model.should_receive(:login).once.with(no_args()).and_return(true)
        @ssq.model.should_receive(:metadata).once.with(no_args()).and_return(metadata)
        @ssq.model.should_receive(:query).once.with(nil).and_return(expected)
        @ssq.model.should_receive(:sync).once.with(no_args()).and_return(true)
        @ssq.model.should_receive(:logoff).once.with(no_args()).and_return(nil)
        @ssq.do_sync
      end
    end

    it "should do query with no exception" do
      verify_read_operation('query')
    end

    it "should do query with no exception pass through" do
      verify_read_operation_pass_through('query')
    end

    it "should do query with exception raised" do
      verify_read_operation_with_error('query')
    end

    it "should do query with exception raised and update refresh time only after retries limit is exceeded" do
      @s.retry_limit = 1
      msg = "Error during query"
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                            :errors => {'query-error'=>{'message'=>msg}}})
      # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
      @s.read_state.retry_counter.should == 1
      @s.read_state.refresh_time.should <= Time.now.to_i

      # try once more and fail again
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                            :errors => {'query-error'=>{'message'=>msg}}})

      # 2) if retry_limit is set to N and number of retries exceeded it - update refresh_time
      @s.read_state.retry_counter.should == 0
      @s.read_state.refresh_time.should > Time.now.to_i
    end

    it "should do query with exception raised and restore state with succesfull retry" do
      @s.retry_limit = 1
      msg = "Error during query"
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                             :errors => {'query-error'=>{'message'=>msg}}})
      # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
      @s.read_state.retry_counter.should == 1
      @s.read_state.refresh_time.should <= Time.now.to_i

      # try once more (with success)
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      @ssq.do_sync
      verify_doc_result(@s, {:md => expected,
                             :errors => {}})
      @s.read_state.retry_counter.should == 0
      @s.read_state.refresh_time.should > Time.now.to_i
    end

    it "should reset the retry counter if prev_refresh_time was set more than poll_interval secs ago" do
      @s.retry_limit = 3
      @s.poll_interval = 2
      msg = "Error during query"
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                            :errors => {'query-error'=>{'message'=>msg}}})
      # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
      @s.read_state.retry_counter.should == 1
      @s.read_state.refresh_time.should <= Time.now.to_i

      # 2) Make another error - results are the same
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                        :errors => {'query-error'=>{'message'=>msg}}})
      @s.read_state.retry_counter.should == 2
      @s.read_state.refresh_time.should <= Time.now.to_i

      # wait until time interval exprires and prev_refresh_time is too old -
      # this should reset the counter on next request with error
      # and do not update refresh_time
      sleep(3)
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                              :errors => {'query-error'=>{'message'=>msg}}})
      @s.read_state.retry_counter.should == 1
      @s.read_state.refresh_time.should <= Time.now.to_i
    end

    it "should do query with exception raised and update refresh time if retry_limit is 0" do
      @s.retry_limit = 0
      msg = "Error during query"
      set_test_data('test_db_storage',{},msg,"query error")
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                            :errors => {'query-error'=>{'message'=>msg}}})
      #  if poll_interval is set to 0 - refresh time should be updated
      @s.read_state.retry_counter.should == 0
      @s.read_state.refresh_time.should > Time.now.to_i
    end

    it "should do query with exception raised and update refresh time if poll_interval == 0" do
      @s.retry_limit = 1
      @s.poll_interval = 0
      msg = "Error during query"
      set_test_data('test_db_storage',{},msg,"query error")
      prev_refresh_time = @s.read_state.refresh_time
      # make sure refresh time is expired
      sleep(1)
      res = @ssq.do_sync
      verify_doc_result(@s, {:md => {},
                             :errors => {'query-error'=>{'message'=>msg}}})
      #  if poll_interval is set to 0 - refresh time should be updated
      @s.read_state.retry_counter.should == 0
      @s.read_state.refresh_time.should > prev_refresh_time
    end
  end

  describe "push_notify" do
    it "should do push_notify for source after push_objects if enabled" do
      @s.push_notify = 'true'
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      ping_params = {'user_id'=>["testuser"], 'sources'=>["SampleAdapter"]}
      PingJob.should_receive(:perform).once.with(ping_params)
      po_handler = lambda { @model.push_objects(params) }
      push_objects_handler = Rhoconnect::Handler::PluginCallbacks::Runner.new(po_handler, @model, {'objects' => data})
      push_objects_handler.run
    end

    it "should do push_notify for source after push_deletes if enabled" do
      @s.push_notify = 'true'
      u2 = User.create(:login => 'user2')
      @a.users << u2.id
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      ping_params = {'user_id'=>["testuser"], 'sources'=>["SampleAdapter"]}
      PingJob.should_receive(:perform).once.with(ping_params)
      pd_handler = lambda { @model.push_deletes(params) }
      push_deletes_handler = Rhoconnect::Handler::PluginCallbacks::Runner.new(pd_handler, @model, {'objects' => data})
      push_deletes_handler.run
    end

    it "should not do push_notify for user source if not enabled (default)" do
      u2 = User.create(:login => 'user2')
      @a.users << u2.id
      data = {'1' => @product1}
      PingJob.should_receive(:perform).never
      po_handler = lambda { @model.push_objects(params) }
      push_objects_handler = Rhoconnect::Handler::PluginCallbacks::Runner.new(po_handler, @model, {'objects' => data})
      push_objects_handler.run
    end

    it "should not do push_notify for app source" do
      @s.partition = :app
      u2 = User.create(:login => 'user2')
      @a.users << u2.id
      data = {'1' => @product1}
      PingJob.should_receive(:perform).never
      po_handler = lambda { @model.push_objects(params) }
      push_objects_handler = Rhoconnect::Handler::PluginCallbacks::Runner.new(po_handler, @model, {'objects' => data})
      push_objects_handler.run
    end
  end

  describe "create" do
    before (:each) do
      rh = lambda { @model.create(params[:create_object])}
      @ssc = Rhoconnect::Handler::Changes::Engine.new(['create'], @model, rh, {})
      @queue_name = "create"
      @u2_fields = {:login => 'anotheruser'}
      @u2 = User.create(@u2_fields)
      @u2.password = 'testpass'
      @c2_fields = {
        :device_type => 'Android',
        :device_pin => 'efgh',
        :device_port => '4444',
        :user_id => @u2.id,
        :app_id => @a.id
      }
      @c2 = Client.create(@c2_fields,{:source_name => @s_fields[:name]})
      @a.users << @u2.id
    end

    it "should do create where adapter.create returns nil" do
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['2', @product2]]]]}, @c.id, true)
      @ssc.create
      verify_source_queue_data(@s, @queue_name => [])
      verify_doc_result(@c, {:create_errors => {},
                             :create_links => {}})
    end

    it "should do create where adapter.create returns object link" do
      @product4['link'] = 'test link'
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['4', @product4]]]]},@c.id,true)
      @ssc.create
      verify_source_queue_data(@s, @queue_name => [])
      verify_doc_result(@c, {:create_errors => {},
                          :create_links => {'4'=>{'l'=>'backend_id'}}})
    end

    it "should raise exception on adapter.create" do
      msg = "Error creating record"
      data = add_error_object({'4'=>@product4,'2'=>@product2},msg)
      source_queue_data = []
      data.each do |key, value|
        source_queue_data << [key, value]
      end
      set_source_queue_state(@s, {@queue_name => [[@s.name, source_queue_data]]},@c.id, true)
      @ssc.create
      verify_doc_result(@c, :create_errors =>
        {"#{ERROR}-error"=>{"message"=>msg},ERROR=>data[ERROR]})
    end

    it "should properly process creates for 2 users using same queue" do
      @product3['link'] = 'test link'
      @product4['link'] = 'test link'
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['temp_id1', @product3]]]]},@c.id,true)
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['temp_id2', @product4]]]]},@c2.id,true)
      @s.queue_docname(:create).should == "source:application:#{@s.name}:create"
      @ssc.create
      verify_source_queue_data(@s, @queue_name => [])
      creates_source1 = Source.load(@s.name,
                  {:user_id => @u.id,:app_id => @a.id})
      creates_source2 = Source.load(@s.name,
                  {:user_id => @u2.id,:app_id => @a.id})
      verify_doc_result(creates_source1, {:md => {'backend_id' => @product3}})
      verify_doc_result(creates_source2, {:md => {'backend_id' => @product4}})
      verify_doc_result(@c, {:create_errors => {},
                          :create_links => {'temp_id1'=>{'l'=>'backend_id'}}})
      verify_doc_result(@c2, {:create_errors => {},
                          :create_links => {'temp_id2'=>{'l'=>'backend_id'}}})
    end
  end

  describe "update" do
    before (:each) do
      rh = lambda { @model.update(params[:update_object])}
      @ssu = Rhoconnect::Handler::Changes::Engine.new(['update'], @model, rh, {})
      @queue_name = "update"
    end

    it "should do update with no errors" do
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['4', { 'price' => '199.99' }]]]]},@c.id,true)
      @ssu.update
      verify_source_queue_data(@s, @queue_name => [])
      verify_doc_result(@c, :update_errors => {})
    end

    it "should do update with errors" do
      msg = "Error updating record"
      data = add_error_object({},msg)
      source_queue_data = []
      data.each do |key, value|
        source_queue_data << [key, value]
      end
      # this one will be after the error record - and should remain in the queue
      source_queue_data << ['4', { 'price' => '199.99' }]
      set_source_queue_state(@s, {@queue_name => [[@s.name, source_queue_data]]},@c.id,true)
      set_doc_state(@c, :cd => { ERROR => { 'price' => '99.99' } }
      )
      @ssu.update
      update_data,client_ids = @s.get_queue(@queue_name)
      update_data.should == [[[@s.name, [['4', { 'price' => '199.99'}]]]]]
      client_ids.should == [@c.id]
      verify_doc_result(@c, {:update_errors =>
          {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]},
                             :update_rollback => {ERROR=>{"price"=>"99.99"}}})
    end
  end

  describe "delete" do
    before (:each) do
      rh = lambda { @model.update(params[:delete_object])}
      @ssd = Rhoconnect::Handler::Changes::Engine.new(['delete'], @model, rh, {})
      @queue_name = "delete"
      @u2_fields = {:login => 'anotheruser'}
      @u2 = User.create(@u2_fields)
      @u2.password = 'testpass'
      @c2_fields = {
        :device_type => 'Android',
        :device_pin => 'efgh',
        :device_port => '4444',
        :user_id => @u2.id,
        :app_id => @a.id
      }
      @c2 = Client.create(@c2_fields,{:source_name => @s_fields[:name]})
      @a.users << @u2.id
    end

    it "should do delete with no errors" do
      set_source_queue_state(@s, {@queue_name => [[@s.name, [['4', @product4]]]]}, @c.id, true)
      set_doc_state(@s, :md => {'4'=>@product4,'3'=>@product3})
      set_doc_state(@c, :cd => {'4'=>@product4,'3'=>@product3})
      @ssd.delete
      verify_source_queue_data(@s, @queue_name => [])
      verify_doc_result(@c, :delete_errors => {})
      verify_doc_result(@s, :md => {'3'=>@product3})
      verify_doc_result(@c, :cd => {'3'=>@product3})
    end

    it "should do delete with errors" do
      msg = "Error delete record"
      data = add_error_object({},msg)
      source_queue_data = []
      data.each do |key, value|
        source_queue_data << [key, value]
      end
      # this one will be after the error and should remain in the queue
      source_queue_data << ['2', @product2]
      set_source_queue_state(@s, {@queue_name => [[@s.name, source_queue_data]]}, @c.id, true)
      @ssd.delete
      verify_doc_result(@c, :delete_errors => {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]})
      verify_source_queue_data(@s, @queue_name => [[[@s.name, [['2', @product2]]]]])
    end

    it "should properly process deletes for 2 users using same queue" do
      deletes_source1 = Source.load(@s.name,
                  {:user_id => @u.id,:app_id => @a.id})
      deletes_source2 = Source.load(@s.name,
                  {:user_id => @u2.id,:app_id => @a.id})
      set_source_queue_state(deletes_source1, {@queue_name => [[@s.name, [['4', @product4]]]]},@c.id,true)
      set_source_queue_state(deletes_source2, {@queue_name => [[@s.name, [['3', @product3]]]]},@c2.id,true)
      deletes_source1.queue_docname(:delete).should == "source:application:#{@s.name}:delete"
      deletes_source1.queue_docname(:delete).should == deletes_source2.queue_docname(:delete)
      set_doc_state(deletes_source1, :md => {'4'=>@product4,'2'=>@product2,'3'=>@product3})
      set_doc_state(deletes_source2, :md => {'4'=>@product4,'3'=>@product3, '1'=>@product1})
      set_doc_state(@c, :cd => {'4'=>@product4,'2'=>@product2,'3'=>@product3})
      set_doc_state(@c2, :cd => {'4'=>@product4,'3'=>@product3, '1'=>@product1})
      @ssd.delete
      verify_source_queue_data(@s, @queue_name => [])
      verify_doc_result(@c, :delete_errors => {})
      verify_doc_result(@c2, :delete_errors => {})
      verify_doc_result(deletes_source1, :md => {'2'=>@product2,'3'=>@product3})
      verify_doc_result(deletes_source2, :md => {'4'=>@product4, '1'=>@product1})
      verify_doc_result(@c, :cd => {'2'=>@product2,'3'=>@product3})
      verify_doc_result(@c2, :cd => {'4'=>@product4, '1'=>@product1})
    end
  end

  describe "cud" do
    before (:each) do
      rh = lambda { @model.send(params[:operation].to_sym, params["#{params[:operation]}_object".to_sym]) }
      @sscud = Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], @model, rh, {})
    end

    it "should fail to create Rhoconnect::Handler::Changes::Engine with InvalidArgumentError without source" do
      lambda { Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], nil, nil, {}) }.should raise_error(ArgumentError, 'Unknown source')
    end

    it "should fail to create Rhoconnect::Handler::Changes::Engine with InvalidArgumentError without proc handler" do
      lambda { Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], @model, nil) }.should raise_error(ArgumentError, 'Invalid CUD handler')
    end

    it "should create Rhoconnect::Handler::Changes::Engine" do
      @sscud.model.is_a?(SampleAdapter).should == true
    end

    it "should do process_cud" do
      @create_queue_name = :create
      @update_queue_name = :update
      @u2_fields = {:login => 'anotheruser'}
      @u2 = User.create(@u2_fields)
      @u2.password = 'testpass'
      @c2_fields = {
        :device_type => 'Android',
        :device_pin => 'efgh',
        :device_port => '4444',
        :user_id => @u2.id,
        :app_id => @a.id
      }
      @c2 = Client.create(@c2_fields,{:source_name => @s_fields[:name]})
      @a.users << @u2.id
      create_doc1 = { 'name' => 'abc', 'link' => '1', 'an_attribute' => "My attrib 2" }
      create_doc2 = { 'name' => 'name0', 'link' => '1' }
      create_doc3 = { 'name' => 'name7', 'link' => '7' }
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['4', create_doc1]]]]},@c.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['5', create_doc2]]]]},@c2.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['6', create_doc3]]]]},@c.id,true)
      set_doc_state(@c, :cd => {'10'=> {'name' => 'Apple'}})
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['10', { 'name' => 'Android' }]]]]},@c.id,true)
      # should receive login/logoff pair twice for create and once for update
      @sscud.should_receive(:auth_method).exactly(6).times.and_return(true)
      @sscud.should_receive(:_process_create).exactly(3).times
      @sscud.should_receive(:_process_update).once
      @sscud.should_not_receive(:_process_delete)
      @sscud.do_cud
    end
  end

  describe "cud conflicts" do
    before (:each) do
      @create_queue_name = :create
      @update_queue_name = :update
      @delete_queue_name = :delete
      rh = lambda { @model.send(params[:operation].to_sym, params["#{params[:operation]}_object".to_sym]) }
      @sscud = Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], @model, rh, {})
      @u2_fields = {:login => 'anotheruser'}
      @u2 = User.create(@u2_fields)
      @u2.password = 'testpass'
      @c2_fields = {
        :device_type => 'Android',
        :device_pin => 'efgh',
        :device_port => '4444',
        :user_id => @u2.id,
        :app_id => @a.id
      }
      @c2 = Client.create(@c2_fields,{:source_name => @s_fields[:name]})
      @a.users << @u2.id
    end

    it "should detect create conflict and skip the duplicate record creation, but properly update the links" do
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['4', { 'name' => 'Android', 'link' => '1' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['5', { 'name' => 'Android', 'link' => '1', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '0', 'duplicate_of_queue_index' => '0' }]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @create_queue_name => [])
      verify_doc_result(@c, :create_errors => {})
      verify_doc_result(@c, :create_links => {'4'=> { 'l' => 'backend_id' }, '5' => { 'l' => 'backend_id'}})
    end

    it "should detect create conflict and skip the duplicate record creation, but properly update the errors page" do
      create_doc1 = { 'name' => 'wrongname', 'link' => '1', 'an_attribute' => "Create Sample Adapter Error" }
      create_doc2 = { 'name' => 'wrongname', 'link' => '1', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '0', 'duplicate_of_queue_index' => '0'}
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['4', create_doc1]]]]},@c.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['5', create_doc2]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @create_queue_name => [])
      verify_doc_result(@c, :create_errors => {"4-error"=>{"message"=>"Create Sample Adapter Error"},
                                                   '4' => create_doc1,
                                                   "5-error"=>{"message"=>"Create Sample Adapter Error"},
                                                   '5' => create_doc2})
      verify_doc_result(@c, :create_links => {})
    end

    it "should detect create conflict and force and error" do
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['4', { 'name' => 'Android', 'link' => true }]]]]},@c.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['5', { 'name' => 'Android', 'link' => '1', 'force_duplicate_error' => '1' }]]]]},@c.id,true)
      @sscud.do_cud
      verify_source_queue_data(@s, @create_queue_name => [])
      verify_doc_result(@c, :create_errors => {"5-error"=>{"message"=>"Error during create: object confict detected"}, "5"=>{"name"=>"Android", "link"=>"1", 'force_duplicate_error' => '1'}} )
    end

    it "should detect create conflict in the intermediate state create and skip the duplicate record create" do
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['5', { 'name' => 'InvalidName', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '1', 'duplicate_of_queue_index' => '0'}], ['4', { 'name' => 'Android' , 'link' => true}]]]]},@c.id,true)
      set_source_queue_state(@s, {@create_queue_name => [[@s.name, [['6', { 'name' => 'iPhone', 'link' => true }], ['7', { 'name' => 'InvalidName', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '1', 'duplicate_of_queue_index' => '0'}]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @create_queue_name => [])
      verify_doc_result(@c, :create_errors => {})
      verify_doc_result(@c, :create_links => {'4'=> { 'l' => 'backend_id' }, '5'=> { 'l' => 'backend_id' }, '6' => { 'l' => 'backend_id' }, '7'=> { 'l' => 'backend_id' }})
    end

    it "should detect update conflict and skip the duplicate record update" do
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'InvalidName', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '0', 'duplicate_of_queue_index' => '0'}]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @update_queue_name => [])
      verify_doc_result(@c, :update_errors => {})
      verify_doc_result(@c, :update_rollback => {})
    end

    it "should detect update conflict and force an error on duplicate record update" do
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'ErrorName', 'force_duplicate_error' => '1' }]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @update_queue_name => [])
      verify_doc_result(@c, :update_errors => {"4-error"=>{"message"=>"Error during update: object confict detected"}, "4"=>{"name"=>"ErrorName", 'force_duplicate_error' => '1'}})
      verify_doc_result(@c, :update_rollback => {'4'=> {'name' => 'Apple'}})
    end

    it "should install find_duplicates_on_update , detect equal objects conflict and skip the duplicate record update" do
      SampleAdapter.enable :find_duplicates_on_update
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_doc_state(@c2, :cd => {'4'=> {'name' => 'Apple'}})
      update_source1 = Source.load(@s.name,
                  {:user_id => @u.id,:app_id => @a.id})
      update_source2 = Source.load(@s.name,
                  {:user_id => @u2.id,:app_id => @a.id})
      set_source_queue_state(update_source1, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c.id,true)
      set_source_queue_state(update_source2, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c2.id, true)
      operation_data,client_ids = update_source2.get_queue(:update)
      invalid_meta = @sscud.model.run_validators(:update,operation_data,client_ids)
      invalid_meta.should == { 1=> {@s.name => { 0 => { :duplicate_of=>true }}},
                               0=>{@s.name => { 0 => { :duplicates=>[{:client_id=>@c2.id, :key=>"4", :value=>{"name"=>"Android"}}]}}}}

      @sscud.model.should_receive(:find_duplicates_on_update).once.and_return(invalid_meta)
      @sscud.do_cud

      verify_source_queue_data(@s, @update_queue_name => [])
      verify_doc_result(@c, :update_errors => {})
      verify_doc_result(@c, :update_rollback => {})
      SampleAdapter.validators.delete(:find_duplicates_on_update)
    end

    it "should detect update conflict and force an error on duplicate record update" do
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@update_queue_name => [[@s.name, [['4', { 'name' => 'ErrorName', 'force_duplicate_error' => '1' }]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @update_queue_name => [])
      verify_doc_result(@c, :update_errors => {"4-error"=>{"message"=>"Error during update: object confict detected"}, "4"=>{"name"=>"ErrorName", 'force_duplicate_error' => '1'}})
      verify_doc_result(@c, :update_rollback => {'4'=> {'name' => 'Apple'}})
    end

    it "should install find_duplicates_on_update , detect equal objects conflict and raise a custom error" do
      SampleAdapter.enable :find_duplicates_on_update, :raise_error => true do |options, invalid_meta, operation, operation_data, client_ids|
        invalid_meta.each do |index, index_data|
          index_data.each do |source_id, objindex_data|
            objindex_data.each do |objindex, objmeta|
              if objmeta.has_key?(:error)
                objmeta[:error] = "My custom error"
              end
            end if objindex_data
          end if index_data
        end if invalid_meta
        invalid_meta
      end
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_doc_state(@c2, :cd => {'4'=> {'name' => 'Apple'}})
      update_source1 = Source.load(@s.name,
                  {:user_id => @u.id,:app_id => @a.id})
      update_source2 = Source.load(@s.name,
                  {:user_id => @u2.id,:app_id => @a.id})
      set_source_queue_state(update_source1, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c.id,true)
      set_source_queue_state(update_source2, {@update_queue_name => [[@s.name, [['4', { 'name' => 'Android' }]]]]},@c2.id, true)
      operation_data,client_ids = update_source2.get_queue(:update)
      invalid_meta = @sscud.model.run_validators(:update,operation_data,client_ids)
      invalid_meta.should == {1=>{@s.name=>{0=>{:error=>"My custom error"}}}}

      @sscud.do_cud
      verify_source_queue_data(@s, @update_queue_name => [])
      verify_doc_result(@c, :update_errors => {})
      verify_doc_result(@c, :update_rollback => {})
      verify_doc_result(@c2, :update_errors => {"4-error"=>{"message"=>"My custom error"}, "4"=>{"name"=>"Android"}})
      verify_doc_result(@c2, :update_rollback => {'4'=> {'name' => 'Apple'}})
      SampleAdapter.validators.delete(:find_duplicates_on_update)
    end


    it "should detect delete conflict and skip the duplicate record delete" do
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_doc_state(@c, :cd_size => 1)
      set_source_queue_state(@s, {@delete_queue_name => [[@s.name, [['4', { 'name' => 'Apple' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@delete_queue_name => [[@s.name, [['4', { 'name' => 'Apple', 'duplicate_of_cid' => @c.id, 'duplicate_of_entry_index' => '0', 'duplicate_of_queue_index' => '0'}]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @delete_queue_name => [])
      verify_doc_result(@c, :cd => {})
      verify_doc_result(@c, :cd_size => '0')
      verify_doc_result(@c, :delete_errors => {})
    end

    it "should detect delete conflict and force an error on duplicate record delete" do
      set_doc_state(@c, :cd => {'4'=> {'name' => 'Apple'}})
      set_doc_state(@c, :cd_size => 1)
      set_source_queue_state(@s, {@delete_queue_name => [[@s.name, [['4', { 'name' => 'Apple' }]]]]},@c.id,true)
      set_source_queue_state(@s, {@delete_queue_name => [[@s.name, [['4', { 'name' => 'Apple', 'force_duplicate_error' => '1'}]]]]},@c.id,true)
      @sscud.do_cud

      verify_source_queue_data(@s, @delete_queue_name => [])
      verify_doc_result(@c, :delete_errors => {"4-error"=>{"message"=>"Error during delete: object confict detected"}, "4"=>{"name"=>"Apple", 'force_duplicate_error' => '1'}})
    end
  end

  describe "search" do
    before (:each) do
      rh = lambda { @model.search(params[:search]) }
      @sss = Rhoconnect::Handler::Search::Engine.new(@model, @c, rh, {})
    end

    it "should do search with no exception" do
      verify_read_operation('search')
    end

     it "should do search with no exception pass through" do
        verify_read_operation_pass_through('search')
      end

    it "should do search with exception raised" do
      verify_read_operation_with_error('search')
    end
  end

  describe "app-level partitioning" do
    it "should create app-level masterdoc with '__shared__' docname" do
      @s1 = Source.load(@s_fields[:name],@s_params)
      @s1.partition = :app
      rh = lambda { @model.query(params[:query]) }
      @model1 = Rhoconnect::Model::Base.create(@s1)
      @ssq = Rhoconnect::Handler::Query::Engine.new(@model1, rh, {})
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @ssq.do_sync
      verify_doc_result(@s1, :md => expected)
      Store.get_store(0).keys("read_state:#{test_app_name}:__shared__*").sort.should ==
        [ "read_state:#{test_app_name}:__shared__:SampleAdapter:refresh_time",
          "read_state:#{test_app_name}:__shared__:SampleAdapter:prev_refresh_time",
          "read_state:#{test_app_name}:__shared__:SampleAdapter:rho__id",
          "read_state:#{test_app_name}:__shared__:SampleAdapter:retry_counter"].sort
    end
  end

  def verify_read_operation(operation)
    expected = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',expected)
    @s.put_data(:errors,
      {"#{operation}-error"=>{'message'=>'failed'}},true)
    if operation == 'query'
      @ssq.run_query.should == true
      verify_doc_result(@s, {:md => expected,
                              :errors => {}})
    else
      @sss.run_search.should == true
      verify_doc_result(@c, {:search => expected,
                            :search_errors => {}})
    end
  end

  def verify_read_operation_pass_through(operation)
    expected = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',expected)
    @s.put_data(:errors,
      {"#{operation}-error"=>{'message'=>'failed'}},true)
    @s.pass_through = 'true'
    if operation == 'query'
      @ssq.run_query.should == expected
      verify_doc_result(@s, {:md => {},
                            :errors => {}})
    else
      @sss.run_search.should == expected
      verify_doc_result(@c, {:search => {},
                            :search_errors => {}})
    end
  end

  def verify_read_operation_with_error(operation)
    msg = "Error during #{operation}"
    set_test_data('test_db_storage',{},msg,"#{operation} error")
    if operation == 'query'
      @ssq.should_receive(:log).with("Model raised #{operation} exception: #{msg}")
      @ssq.should_receive(:log).with(anything)
      @ssq.run_query.should == true
      verify_doc_result(@s, {:md => {},
                             :errors => {'query-error'=>{'message'=>msg}}})
    else
      @sss.should_receive(:log).with("Model raised #{operation} exception: #{msg}")
      @sss.should_receive(:log).with(anything)
      @sss.run_search.should == true
      verify_doc_result(@c, {:search => {},
                             :search_errors => {'search-error'=>{'message'=>msg}}})
    end
  end

  describe "Jobs" do
    it "should enqueue process_cud SourceJob" do
      @s.cud_queue = :cud
      rh = lambda { @model.send(params[:operation].to_sym, params["#{params[:operation]}_object".to_sym]) }
      @sscud = Rhoconnect::Handler::Changes::Engine.new(['create', 'update', 'delete'], @model, rh, {})
      @sscud.do_cud
      Resque.peek(:cud).should == {"args"=>
        ["cud", @s.name, @a.name, @u.login, nil], "class"=>"Rhoconnect::SourceJob"}
    end

    it "should enqueue process_query SourceJob" do
      @s.query_queue = :abc
      rh = lambda { @model.query(params[:query]) }
      @ssq = Rhoconnect::Handler::Query::Engine.new(@model, rh, { :query => {'foo'=>'bar'} })
      @ssq.do_sync
      Resque.peek(:abc).should == {"args"=>
        ["query", @s.name, @a.name, @u.login, {'foo'=>'bar'}], "class"=>"Rhoconnect::SourceJob"}
    end
  end
end