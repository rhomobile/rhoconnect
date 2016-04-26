require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiUserGetDbDoc" do
  include_examples "ApiHelper"

  it "should get user's db document by doc key and data" do
    data = {'1' => {'foo' => 'bar'}}
    dockey = 'myuserdoc'
    post "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{@s2.name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok

    get "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{@s2.name}/docs/#{dockey}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    JSON.parse(last_response.body).should == data
  end
end