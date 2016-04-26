require 'rhoconnect/test_methods'
require File.join(File.dirname(__FILE__),'spec_helper')

describe "TestMethods" do
  # The module we're testing
  include Rhoconnect::TestMethods
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    Rhoconnect.bootstrap(get_testapp_path)
    setup_test_for(SampleAdapter,'user1')
  end

  let(:schema_string) { "{\"property\":{\"brand\":\"string\",\"name\":\"string\"},\"version\":\"1.0\"}" }
  let(:foo_bar) { "{\"foo\":\"bar\"}" }

  it "should setup_test_for an adapter and user" do
    @u.is_a?(User).should == true
    @s.is_a?(Source).should == true
    @query_engine.is_a?(Rhoconnect::Handler::Query::Engine).should == true
    @cud_engine.is_a?(Rhoconnect::Handler::Changes::Engine).should == true
    @search_engine.is_a?(Rhoconnect::Handler::Search::Engine).should == true
    @query_engine.model.is_a?(SampleAdapter).should == true
    @cud_engine.model.is_a?(SampleAdapter).should == true
    @search_engine.model.is_a?(SampleAdapter).should == true
    @u.login.should == 'user1'
    @s.name.should == 'SampleAdapter'
    @c.id.size.should == 32
    @c.device_pin.should == 'abcd'
    @c.device_port.should == '3333'
    @c.device_type.should == 'Apple'
    @c.user_id.should == 'user1'
    @c.app_id.should == 'application'
  end

  it "should include test_schema helper" do
    mock_schema_method([SampleAdapter]) do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @query_engine.do_sync
      JSON.parse(test_schema).should == JSON.parse(schema_string)
    end
  end

  it "should include test_metadata helper" do
    mock_metadata_method([SampleAdapter]) do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @query_engine.do_sync
      JSON.parse(test_metadata).should == JSON.parse(foo_bar)
    end
  end

  it "should include test_query helper" do
    expected = {'1'=>@product1,'2'=>@product2}
    set_state('test_db_storage' => expected)
    test_query.should == expected
  end

  it "should include test_query helper when pass through" do
    expected = {'1'=>@product1,'2'=>@product2}
    set_state('test_db_storage' => expected)
    @s.pass_through = 'true'
    test_query.should == expected
  end

  it "should include query_errors helper" do
    expected =  {"query-error"=>{'message'=>'failed'}}
    set_doc_state(@s, :errors => expected)
    query_errors.should == expected
  end

  it "should include test_create helper" do
    @product4['link'] = 'test link'
    test_create(@product4).should == 'backend_id'
  end

  it "should include test_create helper when pass through" do
    @s.pass_through = 'true'
    test_create(@product4).should == {'processed' => ["temp-id"]}.to_json
  end

  it "should include create_errors helper" do
    expected =  {"create-error"=>{'message'=>'failed'}}
    set_doc_state(@c, :create_errors => expected)
    create_errors.should == expected
  end

  it "should include test_update helper" do
    record = {'4'=> { 'price' => '199.99' }}
    test_update(record)
    verify_source_queue_data(@s, "update:post:/" => [])
  end

  it "should include test_update helper when pass through" do
    record = {'4'=> { 'price' => '199.99' }}
    @s.pass_through = 'true'
    test_update(record).should == {'processed' => ["4"]}.to_json
    verify_source_queue_data(@s, "update:post:/" => [])
  end

  it "should include update_errors helper" do
    expected =  {"update-error"=>{'message'=>'failed'}}
    set_doc_state(@c, :update_errors => expected)
    update_errors.should == expected
  end

  it "should include test_delete helper" do
    record = {'4'=> { 'price' => '199.99' }}
    test_delete(record)
    verify_source_queue_data(@s, "delete:post:/" => [])
  end

  it "should include test_delete helper when pass through" do
    record = {'4'=> { 'price' => '199.99' }}
    @s.pass_through = 'true'
    test_delete(record).should == {'processed' => ["4"]}.to_json
    verify_source_queue_data(@s, "delete:post:/" => [])
  end

  it "should include delete_errors helper" do
    expected =  {"delete-error"=>{'message'=>'failed'}}
    set_doc_state(@c, :delete_errors => expected)
    delete_errors.should == expected
  end

  it "should include md helper" do
    set_doc_state(@s, :md => @data)
    md.should == @data
  end

  it "should include cd helper" do
    set_doc_state(@c, :cd => @data)
    cd.should == @data
  end

  it "should search backend based on params and build a hash of hashes" do
    expected = {'1'=>@product1,'2'=>@product2, '3'=>@product3}
    set_state('test_db_storage' => expected)
    # SampleAdapter has search method by key 'name'
    test_search({'name' => 'iPhone'}).should == { '1' => @product1 }
    test_search('name' => 'G2').should == { '2' => @product2 }
    test_search({'name' => 'Fuze'}).should  == { '3' => @product3 }
    test_search({'name' => 'Some Cool Gadget'}).should  == {}
  end
end