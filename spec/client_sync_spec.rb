require File.join(File.dirname(__FILE__),'spec_helper')

describe "ClientSync" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  it "should handle receive cud for dynamic adapter" do
    Rhoconnect.appserver = "http://test.com"
    params = {'create'=>{'1'=>@product1}}
    @c.source_name = 'Product2'
    # create handler
    lv = lambda { @model.create(@params[:create_object]) }
    @model = Rhoconnect::Model::Base.create(@s2)
    @cs1 = Rhoconnect::Handler::Changes::Runner.new(['create'],@model,@c,lv,params)
    stub_request(:post, "http://test.com/rhoconnect/authenticate")
    stub_request(:post, "http://test.com/rhoconnect/create").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5}.to_json)
    @cs1.run
    verify_source_queue_data(@s2, {:create => [],
                        :update => [],
                        :delete => []})
  end

  let(:mock_schema) { {"property" => { "name" => "string", "brand" => "string" }, "version" => "1.0"} }
  let(:sha1) { get_sha1(mock_schema['version']) }

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    # CUD handler
    rhcud = lambda { @model.send params[:operation].to_sym, params["#{params[:operation]}_object".to_sym] }
    @model = Rhoconnect::Model::Base.create(@s)
    @cud_handler = Rhoconnect::Handler::Changes::Runner.new(['create','update','delete'],@model,@c,rhcud,{})

    # query handler
    params = {:p_size => 2}
    lv = lambda { @model.query(@params[:query]) }
    @sync_handler = Rhoconnect::Handler::Query::Runner.new(@model,@c, lv, params)
  end

  it "should handle receive cud" do
    @cud_handler.params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
    @cud_handler.run
    verify_source_queue_data(@s, {:create => [],
                        :update => [],
                        :delete => []})
  end

  it "should handle receive cud that triggers processing of the previously queued data" do
    queued_create_data = [[@s.name, [['1', @product1]]]]
    set_source_queue_state(@s, {:create => queued_create_data}, @c.id)
    verify_source_queue_data(@s, {:create => [queued_create_data],
                        :update => [],
                        :delete => []})
    @cud_handler.run
    verify_source_queue_data(@s, {:create => [],
                        :update => [],
                        :delete => []})
  end

  it "should handle receive cud from the custom queue_key that triggers processing of the previously queued data" do
    queue_key = "post:/my_custom_create_route"
    queue_name = "create:#{queue_key}"
    Source.define_valid_queues([queue_name])
    queued_create_data = [[@s.name, [['1', @product1]]]]
    set_source_queue_state(@s, {queue_name => queued_create_data}, @c.id)
    verify_source_queue_data(@s, {queue_name => [queued_create_data]})
    @cud_handler.params[:queue_key] = queue_key
    @cud_handler.engine.params[:queue_key] = queue_key
    @cud_handler.operations = ["create"]
    @cud_handler.engine.operations = ["create"]
    @cud_handler.run
    verify_source_queue_data(@s, {queue_name => []})
  end

  it "should handle receive cud with pass through" do
    params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
    @s.pass_through = 'true'

    rhcud = lambda { @model.send params[:operation].to_sym, params["#{params[:operation]}_object".to_sym] }
    @cud_handler = Rhoconnect::Handler::Changes::PassThroughRunner.new(['create','update','delete'],@model,@c,rhcud,params)
    JSON.parse(@cud_handler.run).should == {"processed" => ['1', '2', '3']}
  end

  it "should handle exeptions in receive cud with pass through" do
    params = {'create'=>{'1'=>@error},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
    @s.pass_through = 'true'
    rhcud = lambda { @model.send params[:operation].to_sym, params["#{params[:operation]}_object".to_sym] }
    @cud_handler = Rhoconnect::Handler::Changes::PassThroughRunner.new(['create','update','delete'],@model,@c,rhcud,params)
    JSON.parse(@cud_handler.run).should == {"error" => {"message" => "undefined method `[]' for nil:NilClass" }, "processed" => []}
  end

  it "should handle send cud" do
    data = {'1'=>@product1,'2'=>@product2}
    expected = {'insert'=>data}
    set_test_data('test_db_storage',data)
    @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>@c.get_value(:page_token)},
      {'count'=>data.size},{'progress_count'=>0},
      {'total_count'=>data.size},expected]
    verify_doc_result(@sync_handler.client, {:page => data,
                                   :delete_page => {},
                                   :cd => data})
  end

  it "should handle send cud with page size 0" do
    data = {'1'=>@product1,'2'=>@product2}
    expected = {}
    set_test_data('test_db_storage',data)
    @sync_handler.p_size = 0
    @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>''},
      {'count'=>0},{'progress_count'=>0},
      {'total_count'=>data.size},expected]
    verify_doc_result(@sync_handler.client, {:page => expected,
                                   :delete_page => {},
                                   :cd => expected})
  end

  it "should handle send cud for dynamic adapter" do
    Rhoconnect.appserver = "http://test.com"
    data = {'1'=>@product1}
    expected = {'insert'=>data}
    stub_request(:post, "http://test.com/rhoconnect/authenticate")
    stub_request(:post, "http://test.com/rhoconnect/query").with(:headers => {'Content-Type' => 'application/json'}).to_return(:status => 200, :body => data.to_json)

    @c.source_name = 'Product2'
    # query handler
    lv = lambda { @model.query(params[:query]) }
    params = { :p_size => 2 }
    @model = Rhoconnect::Model::Base.create(@s2)
    @cs1 = Rhoconnect::Handler::Query::Runner.new(@model,@c, lv, params)
    @cs1.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>@c.get_value(:page_token)},
      {'count'=>data.size},{'progress_count'=>0},
      {'total_count'=>data.size},expected]

    verify_doc_result(@cs1.client, {:page => data,
        :delete_page => {},
        :cd => data})
  end

  it "should handle send cud with pass_through" do
    data = {'1'=>@product1,'2'=>@product2}
    expected = {'insert'=>data}
    set_test_data('test_db_storage',data)
    @s.pass_through = 'true'
    lv = lambda { @model.query(params[:query]) }
    params = { :p_size => 2 }
    @ptsync = Rhoconnect::Handler::Query::PassThroughRunner.new(@model, @c, lv, params)
    @ptsync.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>@c.get_value(:page_token)},
      {'count'=>data.size},{'progress_count'=>0},
      {'total_count'=>data.size},expected]
    verify_doc_result(@ptsync.client, {:page => {},
                                   :cd => {}})
  end

  it "should handle send cud if with pass_through no data" do
    data = {}
    expected = {}
    #set_test_data('test_db_storage',data)
    @s.pass_through = 'true'
    lv = lambda { @model.query(params[:query]) }
    params = { :p_size => 2 }
    @ptsync = Rhoconnect::Handler::Query::PassThroughRunner.new(@model, @c, lv, params)
    @ptsync.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>""},
      {'count'=>data.size},{'progress_count'=>0},
      {'total_count'=>data.size},expected]
    verify_doc_result(@ptsync.client, {:page => {},
                                   :cd => {}})
  end

  it "should return read errors in send cud" do
    msg = "Error during query"
    data = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',data,msg,'query error')
    @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},
      {"source-error"=>{"query-error"=>{"message"=>msg}}}]
  end

  it "should return login errors in send cud" do
    @u.login = nil
    @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
      {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
      {'source-error'=>{"login-error"=>{"message"=>"Error logging in"}}}]
  end

  it "should return logoff errors in send cud" do
    msg = "Error logging off"
    set_test_data('test_db_storage',{},msg,'logoff error')
    @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>@c.get_value(:page_token)},
      {"count"=>1}, {"progress_count"=>0}, {"total_count"=>1},
      {"source-error"=>{"logoff-error"=>{"message"=>msg}},
      "insert"=>{ERROR=>{"name"=>"logoff error", "an_attribute"=>msg}}}]
  end

  describe "send errors in send_cud" do
    it "should handle create errors" do
      receive_and_send_cud('create')
    end

    it "should handle send cud" do
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      set_test_data('test_db_storage',data)
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>@c.get_value(:page_token)},
        {'count'=>data.size},{'progress_count'=>0},
        {'total_count'=>data.size},expected]
      verify_doc_result(@sync_handler.client, {:page => data,
                                 :delete_page => {},
                                 :cd => data})
    end

    it "should return read errors in send cud" do
      msg = "Error during query"
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data,msg,'query error')
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},
        {"source-error"=>{"query-error"=>{"message"=>msg}}}]
    end

    it "should return login errors in send cud" do
      @u.login = nil
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
        {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
        {'source-error'=>{"login-error"=>{"message"=>"Error logging in"}}}]
    end

    it "should return logoff errors in send cud" do
      msg = "Error logging off"
      set_test_data('test_db_storage',{},msg,'logoff error')
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>@c.get_value(:page_token)},
        {"count"=>1}, {"progress_count"=>0}, {"total_count"=>1},
        {"source-error"=>{"logoff-error"=>{"message"=>msg}},
        "insert"=>{ERROR=>{"name"=>"logoff error", "an_attribute"=>msg}}}]
    end

    describe "send errors in send_cud" do
      it "should handle create errors" do
        receive_and_send_cud('create')
      end

      it "should handle update errors" do
        broken_object = { ERROR => { 'price' => '99.99' } }
        set_doc_state(@c, :cd => broken_object)
        set_test_data('test_db_storage',broken_object)
        receive_and_send_cud('update')
      end

      it "should handle delete errors" do
        msg = "Error delete record"
        error_objs = add_error_object({},"Error delete record")
        op_data = {'delete'=>error_objs}
        @cud_handler.params = op_data
        @cud_handler.operations = ["delete"]
        @cud_handler.engine.operations = ["delete"]
        @cud_handler.run
        @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
          {"delete-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>error_objs[ERROR]}}]
      end

      it "should send cud errors only once" do
        msg = "Error delete record"
        error_objs = add_error_object({},"Error delete record")
        op_data = {'delete'=>error_objs}
        @cud_handler.params = op_data
        @cud_handler.operations = ["delete"]
        @cud_handler.engine.operations = ["delete"]
        @cud_handler.run
        @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
          {"delete-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>error_objs[ERROR]}}]
        verify_result(@c.docname(:delete_errors) => {})
        @sync_handler.run.should ==   [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},{}]
      end


    end

    it "should handle receive_cud and perform proper operation on the md and cd" do
      set_doc_state(@s, :md => {'3'=>@product3})
      set_doc_state(@c, :cd => {'3'=>@product3})
      params = {'create'=>{'1'=>@product1},
        'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cud_handler.params = params
      @cud_handler.run
      verify_source_queue_data(@s, {:create => [],
                          :update => [],
                          :delete => []})
      verify_doc_result(@s, :md => {})
      verify_doc_result(@c, :cd => {})
      verify_source_queue_data(@s2, {:create => [],
                        :update => [],
                        :delete => []})
    end

    it "should handle send_cud with query_params" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => {'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @sync_handler.engine.params = {:query => params}
      @sync_handler.run
      verify_doc_result(@s, :md => expected)
      verify_doc_result(@sync_handler.client, :cd => expected)
    end
  end

  describe "search" do
    before(:each) do
      @s_fields[:name] = 'SimpleAdapter'
      @c_fields.delete(:id)
      @c1 = Client.create(@c_fields,{:source_name => @s_fields[:name]})
      @s1 = Source.create(@s_fields,@s_params)
      search_handler = lambda { @model.search(params[:search]) }
      @model1 = Rhoconnect::Model::Base.create(@s2)
      @cs = Rhoconnect::Handler::Search::Runner.new(@model, @c, search_handler, {})
      @cs1 = Rhoconnect::Handler::Search::Runner.new(@model1,@c1, search_handler, { :p_size => 2 })
    end

    def search_and_verify_res(params)
      @cs.params = params
      @cs.engine.params = params
      res = @cs.run
      token = @c.get_value(:search_token)
      res[0]['version'].should == Rhoconnect::SYNC_VERSION
      res[1]['token'].should == token
      res[2]['source'].should == @s.name
      res[3]['count'].should == 1
      res[4]['insert']
    end

    it "should handle search" do
      params = {:search => {'name' => 'iPhone'}}
      set_state('test_db_storage' => @data)
      @cs.engine.params = params
      res = @cs.run
      token = @c.get_value(:search_token)
      res.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>token},
        {'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
      verify_doc_result(@c, {:search => {'1'=>@product1},
                             :search_errors => {}})
    end

    it "should handle search with no params" do
      @cs.p_size = @data.size
      set_state('test_db_storage' => @data)
      res = @cs.run
      token = @c.get_value(:search_token)
      res.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>token},
        {'source'=>@s.name},{'count'=>@data.size},{'insert'=>@data}]
      verify_doc_result(@c, {:search => @data,
                             :search_errors => {}})
    end

    it "should handle search with more than one page" do
      @cs.p_size = 1
      params = {:search => {'name' => 'iPhone'}}
      product4 = {'name' => 'iPhone', 'price' => '99.99'}
      @data['4'] = product4
      set_state('test_db_storage' => @data)
      inserts = search_and_verify_res(params)
      verify_doc_result(@c, {:search => {'1'=>@product1,'4'=>product4},
                         :cd_size => '1',
                         :cd => @c.get_data(:search_page),
                         :search_errors => {}})
      verify_doc_result(@s, {:md_size => '1',
                             :md => @c.get_data(:search_page)})

      # ack the token
      params[:token] = @c.get_value(:search_token)
      new_inserts = search_and_verify_res(params)
      inserts.merge!(new_inserts)
      verify_doc_result(@c, {:search => {'1'=>@product1,'4'=>product4},
                          :cd => inserts,
                          :search_errors => {}})
      verify_doc_result(@s, :md => inserts)
      @c.get_data(:search_page).size.should == 1

      # ack the last token
      params[:token] = @c.get_value(:search_token)
      @cs.params = params
      @cs.run.should == []
      verify_doc_result(@c, {:search => {},
                        :cd => inserts,
                        :search_errors => {},
                        :search_page => {},
                        :search_token => nil})
      verify_doc_result(@s, :md => inserts)
    end

    it "should handle search with nil result" do
      params = {:search => {'name' => 'foo'}}
      set_state('test_db_storage' => @data)
      @cs.engine.params = params
      @cs.run.should == []
      verify_doc_result(@c, {:search => {},
                            :search_errors => {}})
    end

    it "should resend search by search_token" do
      @source = @s
      set_doc_state(@c, :search_page => {'1'=>@product1})
      token = @cs.client.compute_token(:search_token)
      @cs.params = {:resend => true,:token => token}
      @cs.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'token'=>token},{'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
      verify_doc_result(@c, {:search_page => {'1'=>@product1},
        :search_errors => {},
        :search_token => token})
    end

    it "should handle search ack" do
      set_doc_state(@c, {:search => {'1'=>@product1}})
      set_doc_state(@c, {:cd => {'1'=>@product1}})
      token = @cs.client.compute_token(:search_token)
      @cs.params = {:token => token}
      @cs.run.should == []
      verify_doc_result(@c, {:search => {},
        :search_errors => {},
        :search_token => nil})
    end

    it "should return error on invalid ack token" do
      set_doc_state(@c, {:search_page => {'1'=>@product1}})
      set_doc_state(@c, :search_token => 'validtoken')
      params = {:token => 'abc',
                :search => {'name' => 'iPhone'}}
      @cs.params = params
      @cs.engine.params = params
      @cs.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'source'=>@s.name},{'search-error'=>{'search-error'=>
        {'message'=>"Search error - invalid token"}}}]
      verify_doc_result(@c, {:search => {},
                             :search_errors => {},
                             :search_token => nil})
    end

    it "should handle search login error" do
      @u.login = nil
      msg = "Error logging in"
      error = set_test_data('test_db_storage',@data,msg,'search error')
      @cs.engine.params = {:search => {'name' => 'iPhone'}}
      @cs.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{'source'=>@s.name},
        {'search-error'=>{'login-error'=>{'message'=>msg}}}]
      verify_doc_result(@c, {:search => {},
                            :search_token => nil})
    end
  end

  describe "page methods" do
    it "should return diffs between master documents and client documents limited by page size" do
      @s.put_data(:md,@data).should == true
      @s.get_data(:md).should == @data
      @s.put_value(:md_size,@data.size)

      total_count, res = @sync_handler.compute_page
      total_count.to_i.should == 3
      res.each do |key, value|
        @data.has_key?(key).should == true
        @data[key].should == value
      end

      @sync_handler.client.get_value(:cd_size).to_i.should == 0
      @sync_handler.client.get_data(:page).each do |key, value|
        @data.has_key?(key).should == true
        @data[key].should == value
      end
    end

    it "appends diff to the client document" do
      @cd = {'3'=>@product3}
      @c.put_data(:cd,@cd)
      @c.get_data(:cd).should == @cd

      @page = {'1'=>@product1,'2'=>@product2}
      @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

      @c.put_data(:cd,@page,true).should == true
      @c.get_data(:cd).should == @expected
    end

    it "should delete objects from the client document and return deleted objects in the page" do
      @s.put_data(:md,@data).should == true
      @s.get_data(:md).should == @data

      @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}
      @sync_handler.client.put_data(:cd,@cd)
      @sync_handler.client.get_data(:cd).should == @cd

      @expected = {'4'=>@product4}
      @sync_handler.send_new_page
      @sync_handler.client.get_data(:delete_page).should == @expected
      @sync_handler.client.get_data(:cd).should == @data
    end

    it "should resend page if page exists and no token provided" do
      expected = {'1'=>@product1}
      set_test_data('test_db_storage',{'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @sync_handler.engine.params = {:query => params}
      @sync_handler.run
      token = @c.get_value(:page_token)
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
                                   {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},{'insert' => expected}]
      @sync_handler.params[:token] = token
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
                                   {"count"=>0}, {"progress_count"=>0}, {"total_count"=>1}, {}]
      @sync_handler.client.get_data(:page).should == {}
      @c.get_value(:page_token).should be_nil
    end

    it "should send metadata with page" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => expected)
      metadata = "{\"foo\":\"bar\"}"
      mock_metadata_method([SampleAdapter]) do
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        result.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
          {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},
          {'metadata'=>metadata,'insert'=>expected}]
        @c.get_value(:metadata_page).should == metadata
      end
    end

    it "should send metadata with resend page" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => expected)
      mock_metadata_method([SampleAdapter]) do
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
          {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},
          {'metadata'=>"{\"foo\":\"bar\"}",'insert'=>expected}]
      end
    end

    it "should ack metadata page with ack token" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => expected)
      mock_metadata_method([SampleAdapter]) do
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        @sync_handler.params[:token] = token
        @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
          {"count"=>0}, {"progress_count"=>0},{"total_count"=>1},{}]
        @c.get_value(:metadata_page).should be_nil
      end
    end

    it "shouldn't send schema-changed if client schema sha1 is nil" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => expected)
      mock_schema_method([SampleAdapter]) do
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        result.should ==  [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
          {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},{'insert'=>expected}]
        @c.get_value(:schema_sha1).should == sha1
      end
    end

    it "should send schema-changed instead of page" do
      mock_schema_method([SampleAdapter]) do
        @c.put_value(:schema_sha1,'foo')
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        result.should ==  [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
          {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{'schema-changed'=>'true'}]
        @c.get_value(:schema_page).should == sha1
        @c.get_value(:schema_sha1).should == sha1
      end
    end

    it "should re-send schema-changed if no token sent" do
      mock_schema_method([SampleAdapter]) do
        @c.put_value(:schema_sha1,'foo')
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        @sync_handler.run.should ==  [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>token},
          {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{'schema-changed'=>'true'}]
        @c.get_value(:schema_page).should == sha1
        @c.get_value(:schema_sha1).should == sha1
      end
    end

    it "should ack schema-changed with token" do
      mock_schema_method([SampleAdapter]) do
        @c.put_value(:schema_sha1,'foo')
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        @sync_handler.params[:token] = token
        @sync_handler.run.should ==  [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
          {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{}]
        @c.get_value(:schema_page).should be_nil
        @c.get_value(:schema_sha1).should == sha1
      end
    end

    it "should expire bulk data if schema changed" do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :sources => [@s_fields[:name]])
      data.refresh_time = Time.now.to_i + 600
      mock_schema_method([SampleAdapter]) do
        @c.put_value(:schema_sha1,'foo')
        result = @sync_handler.run
        token = @c.get_value(:page_token)
        @sync_handler.params[:token] = token
        @sync_handler.run.should ==  [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""},
          {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{}]
        @c.get_value(:schema_page).should be_nil
        @c.get_value(:schema_sha1).should == sha1
        data = BulkData.load(docname)
        data.refresh_time.should <= Time.now.to_i
      end
    end
  end

  def receive_and_send_cud(operation)
    msg = "Error #{operation} record"
    op_data = {operation=>{ERROR=>{'an_attribute'=>msg,'name'=>'wrongname'}}}
    @cud_handler.operations = [operation]
    @cud_handler.engine.operations = [operation]
    @cud_handler.params = op_data
    @cud_handler.run
    if operation == 'update'
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>1},
        {
          "update-rollback"=>{"0_broken_object_id"=>{"price"=>"99.99"}},
          "#{operation}-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>op_data[operation][ERROR]}
        }]
    else
      @sync_handler.run.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
        {"#{operation}-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>op_data[operation][ERROR]}}]
    end
  end
end