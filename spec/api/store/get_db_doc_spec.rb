require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiGetDbDoc" do
  include_examples "ApiHelper"

  it "should return db document by name" do
    data = {'1' => {'foo' => 'bar'}}
    set_state('abc:abc' => data)
    dockey = 'abc:abc'
    get "/rc/#{Rhoconnect::API_VERSION}/store/#{dockey}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    JSON.parse(last_response.body).should == data
  end

  it "should return db document by name and print deprecation warning with old route" do
    data = {'1' => {'foo' => 'bar'}}
    set_state('abc:abc' => data)
    post "/api/get_db_doc", {:doc => 'abc:abc'}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    JSON.parse(last_response.body).should == data
  end

  it "should return db document by name and data_type" do
    data = 'some string'
    set_state('abc:abc' => data)
    dockey = 'abc:abc'
    get "/rc/#{Rhoconnect::API_VERSION}/store/#{dockey}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.body.should == data
  end
end