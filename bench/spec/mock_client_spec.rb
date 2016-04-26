$:.unshift File.join(File.dirname(__FILE__))
require 'bench_spec_helper'

describe "MockClient" do
  include_examples "BenchSpecHelper"

  before(:each) do
    @mc = MockClient.new(1,2,123)
  end

  it "should return document type" do
    @mc.doc_type.should == "123:mock:cd"
  end

  it "should insert objects into the client document" do
    @mc.insert(@data)
    verify_result(@mc.doc_type => @data)
  end

  it "should delete objects from the client document" do
    set_state(@mc.doc_type => @data)
    @mc.delete('1' => @product1,'3' => @product3)
    verify_result(@mc.doc_type => {'2' => @product2})
  end

  it "should verify state of the client document" do
    set_state(@mc.doc_type => @data)
    @mc.verify(@data).should == true
    @mc.verify('1' => @product1,'3' => @product3).should == false
  end

  it "should parse server message and insert objects into the client document" do
    message = [{:version => 3},{:token=>'123'},{:count=>3},{:progress_count=>0},{:total_count=>3},{:insert=>@data}].to_json
    @mc.parse message
    verify_result(@mc.doc_type => @data)
  end

  it "should parse server message and delete objects for the client document" do
    set_state(@mc.doc_type => @data)
    message = [{:version => 3},{:token=>'123'},{:count=>3},{:progress_count=>0},{:total_count=>3},{:delete=>{'2'=>@product2}}].to_json
    @mc.parse message
    verify_result(@mc.doc_type => {'1' => @product1,'3' => @product3})
  end

  it "should parse server message and insert/delete objects to/from client document" do
    set_state(@mc.doc_type => {'1' => @product1,'2' => @product2})
    message = [{:version => 3},{:token=>'123'},{:count=>3},{:progress_count=>0},{:total_count=>3},
      {:insert=>{'3'=>@product3}},{:delete=>{'2'=>@product2}}].to_json
    @mc.parse message
    verify_result(@mc.doc_type => {'1' => @product1,'3' => @product3})
  end

  it "should raise exception on wrong message format" do
    message = [{:version => 3},{:token=>'123'},{:count=>3},{:progress_count=>0}].to_json
    lambda { @mc.parse message }.should raise_error(Exception,
      '[T:001|I:002] Wrong message format. Message: "[{\"version\":3},{\"token\":\"123\"},{\"count\":3},{\"progress_count\":0}]"')
  end

  it "should raise exception on wrong protocol version" do
    message = [{:version => 1},{:token=>'123'},{:count=>3},{:progress_count=>0},{:total_count=>0},{}].to_json
    lambda { @mc.parse message }.should raise_error(Exception,
      '[T:001|I:002] Wrong protocol version. Message: "[{\"version\":1},{\"token\":\"123\"},{\"count\":3},{\"progress_count\":0},{\"total_count\":0},{}]"')
  end
end