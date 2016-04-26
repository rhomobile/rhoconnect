require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiUpdateUser" do
  include_examples "ApiHelper"

  it "should update user successfully" do
    login = 'rhoadmin'
    put "/rc/#{Rhoconnect::API_VERSION}/users/#{login}", {:attributes => {:new_password => '123'}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    user = User.authenticate('rhoadmin','123')
    user.login.should == 'rhoadmin'
    user.admin.should == 1
  end

  it "should update user successfully with old route and print deprecation warning" do
    login = 'rhoadmin'
    post "/api/update_user", {:api_token => @api_token, :user_id => login,
      :attributes => {:new_password => '123'}}
    last_response.should be_ok
    user = User.authenticate('rhoadmin','123')
    user.login.should == 'rhoadmin'
    user.admin.should == 1
  end

  it "should fail to update user with wrong attributes" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    User.is_exist?(params[:attributes][:login]).should == true

    put "/rc/#{Rhoconnect::API_VERSION}/users/#{params[:attributes][:login]}", {:attributes => {:missingattrib => '123'}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.status.should == 500
    last_response.body.match('undefined method').should_not be_nil
  end

  it "should not update login attribute for user" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    User.is_exist?(params[:attributes][:login]).should == true

    put "/rc/#{Rhoconnect::API_VERSION}/users/#{params[:attributes][:login]}",
      {:attributes => {:new_password => '123', :login => 'someotheruser1'}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    user = User.authenticate('testuser1','123')
    user.login.should == 'testuser1'
    user.admin.should_not == 1
    User.is_exist?('someotheruser1').should == false
  end
end