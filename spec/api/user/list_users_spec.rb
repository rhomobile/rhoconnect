require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiListUsers" do
  include_examples "ApiHelper"

  it "should list users" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    get "/rc/#{Rhoconnect::API_VERSION}/users", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).sort.should == ["testuser", "testuser1"].sort
  end

  it "should handle empty user's list" do
    @a.delete; @a = App.create(@a_fields)
    get "/rc/#{Rhoconnect::API_VERSION}/users", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == []
  end

  it "should show the deprecation warning on /api/list_users" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    post "/api/list_users", {:api_token => @api_token}
    JSON.parse(last_response.body).sort.should == ["testuser", "testuser1"].sort
    last_response.headers['Warning'].index('deprecated').should_not == nil
  end
end