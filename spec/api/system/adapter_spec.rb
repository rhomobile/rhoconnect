require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiAppServer" do
  include_examples "ApiHelper"

  it "should save adapter url" do
    params = {:attributes => {:adapter_url => 'http://test.com'}}
    post "/rc/#{Rhoconnect::API_VERSION}/system/appserver", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
  end

  it "should get adapter url" do
    params = {}
    get "/rc/#{Rhoconnect::API_VERSION}/system/appserver", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
  end

  it "should get check deprecation warning in /api/get_adapter" do
    params = {}
    post "/api/get_adapter", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
  end

  it "should get check deprecation warning in /api/source/get_adapter" do
    params = {}
    post "/api/source/get_adapter", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
  end
end
