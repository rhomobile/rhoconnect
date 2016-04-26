require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiCreateUser" do
  include_examples "ApiHelper"

  it "should create user" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    User.load(params[:attributes][:login]).login.should == params[:attributes][:login]
    User.authenticate(params[:attributes][:login],
      params[:attributes][:password]).login.should == params[:attributes][:login]
    @a.users.members.sort.should == [@u.login, params[:attributes][:login]]
  end

  it "should create user and post a deprecation warning with the old route" do
    params = {:api_token => @api_token,
      :attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/api/create_user", params
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    User.load(params[:attributes][:login]).login.should == params[:attributes][:login]
    User.authenticate(params[:attributes][:login],
      params[:attributes][:password]).login.should == params[:attributes][:login]
    @a.users.members.sort.should == [@u.login, params[:attributes][:login]]
  end

  it "should not create user without the api_token" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {}
    last_response.status.should == 422
    User.is_exist?('testuser1').should == false
  end

  it "should not create user with empty login" do
    params = {:attributes => {:login => '', :password => ''}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should_not be_ok
    User.is_exist?('').should == false
  end
end
