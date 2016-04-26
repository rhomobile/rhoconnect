require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiSetDbDoc" do
  include_examples "ApiHelper"

  it "should set db document by doc name and data" do
    data = {'1' => {'foo' => 'bar'}}
    docname = 'application:abc'
    post "/rc/#{Rhoconnect::API_VERSION}/store/#{docname}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result(docname => data)
  end

  it "should set db document by doc name, data type, and data" do
    data = 'some string'
    docname = 'abc:abc:str'
    post "/rc/#{Rhoconnect::API_VERSION}/store/#{docname}", {:data => data, :data_type => :string}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result('abc:abc:str' => data)
  end

  it "should set db document by doc name, data type, and data with old route and deprecation warning" do
    data = 'some string'
    post "/api/set_db_doc", {:doc => 'abc:abc:str', :data => data, :data_type => :string}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.headers['Warning'].index('deprecated').should_not == nil
    last_response.should be_ok
    verify_result('abc:abc:str' => data)
  end

  it "should append data in set db document by doc name and data" do
    data = {'1' => {'foo' => 'bar'}}
    data2 = {'2' => {'foo1' => 'bar1'}}
    data3 = data.merge(data2)
    docname = 'abc:abc'
    post "/rc/#{Rhoconnect::API_VERSION}/store/#{docname}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result('abc:abc' => data)

    post "/rc/#{Rhoconnect::API_VERSION}/store/#{docname}", {:data => data2, :append => true}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result('abc:abc' => data3)
  end
end