require_relative '../../lib/rhoconnect'
require_relative '../../lib/rhoconnect/server'
require_relative '../spec_helper'

describe "Rhoconnect::Model::JsBase" do
  include Rhoconnect

  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :secret, "secure!"
    Rhoconnect.use_node = true
    Rhoconnect.bootstrap(get_testapp_path)
  end

  def app
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  after(:each) do
    Rhoconnect::Node.kill_process
    Source.valid_doctypes.delete('tmpdoc'.to_sym)
  end

  it "should load settings for model" do
    @s = Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id})
    @s.poll_interval.should == 100
  end

  it "should call js model method explicitly" do
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    res = js.login
    res.should == "success"
  end

  it "should print warning if model function not found" do
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    res = js.foo
    res.should == "foo method not defined for JsSample"
  end

  it "should call currentUser from model" do
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    res = js.getUser
    res.should == 'testuser'
  end

  it "should call stashResult from model" do
    data = { '0' => {'name' => '0'}, '1' => {'name' => '1'} }
    Source.define_valid_doctypes(['tmpdoc'.to_sym])
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    js.inject_tmpdoc('tmpdoc')
    js.testStashResult
    js.get_data('tmpdoc').should == data
  end

  it "should test non-nil result from query" do
    data = {'1' => {'name' => 'iPhone'}}
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    js.do_query(test_non_hash: true)
    js.get_data(:md).should == {}
  end

  it "should call getData for a model" do
    data = {'1' => {'name' => 'iPhone'}}
    js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
    js.do_query
    js.testGetModelData.should == data
  end

  it "should call partitionName for a model" do
    JsSample.partition_name('testuser').should == 'testuser_partition'
  end

  context "exceptions" do
    it "should raise ruby Rhoconnect::Model::Exception" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseException
      }.should raise_error(Rhoconnect::Model::Exception, /some custom message/)
    end

    it "should raise ruby Rhoconnect::Model::LoginException" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseLoginException
      }.should raise_error(Rhoconnect::Model::LoginException, /some login message/)
    end

    it "should raise ruby Rhoconnect::Model::LogoffException" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseLogoffException
      }.should raise_error(Rhoconnect::Model::LogoffException, /some logoff message/)
    end

    it "should raise ruby Rhoconnect::Model::ServerTimeoutException" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseTimeoutException
      }.should raise_error(Rhoconnect::Model::ServerTimeoutException, /some timeout message/)
    end

    it "should raise ruby Rhoconnect::Model::ServerErrorException" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseErrorException
      }.should raise_error(Rhoconnect::Model::ServerErrorException, /some error message/)
    end

    it "should raise ruby Rhoconnect::Model::ObjectConflictErrorException" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.testRaiseConflictException
      }.should raise_error(Rhoconnect::Model::ObjectConflictErrorException, /some object conflict message/)
    end

    it "should raise an exception during a regular adapter method" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      lambda {
        js.do_query(raise_an_error: true)
      }.should raise_error(Rhoconnect::Model::ServerErrorException, /query error occured/)
    end
  end

  context "Store" do
    it "should call getValue" do
      Store.put_value('foo', 'bar')
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      res = js.testGetValue
      res.should == 'bar'
    end

    it "should call putValue" do
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      js.testPutValue('foo', 'baz')
      Store.get_value('foo').should == 'baz'
    end

    it "should call getData" do
      data = {'1' => {'name' => 'iPhone'}}
      Store.put_data('foo', data)
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      res = js.testGetData
      res.should == data
    end

    it "should call putData" do
      data = {'1' => {'name' => 'iPhone'}}
      js = JsSample.new(Source.load('JsSample', {:app_id => @a.id, :user_id => @u.id}))
      res = js.testPutData('foo', data)
      Store.get_data('foo').should == data
    end
  end
end
