require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiGetApiToken" do
  include_examples "ApiHelper"

  it "should login and receive the token string" do
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", :login => 'rhoadmin',:password => ''
    last_response.body.should == @api_token
  end

  it "should login using the old route and show deprecation warning" do
    post "/login", :login => 'rhoadmin',:password => ''
    last_response.body.should == @api_token
    last_response.headers["Warning"].index('deprecated').should_not == nil
  end

  it "should fail to login and get token if user is not rhoadmin" do
    Rhoconnect.appserver = nil
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", :login => @u_fields[:login],:password => 'testpass'
    last_response.status.should == 422
    last_response.body.should == 'Invalid/missing API user'
  end

  it "should return 422 if token doesn't belong to the API user" do
    invalid_api_token = ApiToken.create({:value => 'mytoken', :user_id => 'notadmin'})
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => invalid_api_token.value}
    last_response.status.should == 422
    last_response.body.should == 'Invalid/missing API user'
  end

  it "should return 422 if no token provided" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params
    last_response.status.should == 422
  end

  it "response should have cache-control and pragma headers set to no-cache" do
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", :login => 'rhoadmin',:password => ''
    last_response.headers['Cache-Control'].should == 'no-cache'
    last_response.headers['Pragma'].should == 'no-cache'
  end
end