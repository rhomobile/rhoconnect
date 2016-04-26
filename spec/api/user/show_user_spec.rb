require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiShowUser" do
  include_examples "ApiHelper"

  it "should show user" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    get "/rc/#{Rhoconnect::API_VERSION}/users/#{params[:attributes][:login]}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    JSON.parse(last_response.body).should include({"name"=>"login", "value"=>"testuser1", "type"=>"string"})
  end
end