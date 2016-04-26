$:.unshift File.join(File.dirname(__FILE__))
require 'bench_spec_helper'
require 'benchapp/models/ruby/mock_adapter'

describe "MockAdapter" do
  include_examples "BenchSpecHelper"

  before(:each) do
    @s_fields = {
      :source_id => 1,
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => 'mock_user_id',
      :app_id => 'mock_app_id'
    }
    @s = Source.create(@s_fields,@s_params)
    @ma = MockAdapter.new(@s)
  end

  it "should return db name" do
    @ma.db_name.should == "test_db_storage:mock_app_id:mock_user_id"
  end

  it "should return db lock name" do
    @ma.lock_name.should == "lock:test_db_storage:mock_app_id:mock_user_id"
  end

  it "should login" do
    @ma.login.should == true
  end

  it "should query data from db" do
    set_state(@ma.db_name => @data)
    @ma.query.should == @data
  end

  it "should create object in the db" do
    @product1.merge!('mock_id'=>'1')
    @ma.create(@product1).should == '1'
    verify_result(@ma.db_name => {'1' => @product1})
  end

  it "should update object in db" do
    set_state(@ma.db_name => @data)
    @ma.update('id' => '3','price' => '99.99')
    @product3['price'] = '99.99'
    verify_result(@ma.db_name => @data)
  end

  it "should delete object in db" do
    set_state(@ma.db_name => @data)
    del_object = {}.merge!(@product2).merge!('id'=>'2')
    @ma.delete(del_object)
    verify_result(@ma.db_name => {'1' => @product1, '3' => @product3})
  end
end