require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiUserSetDbDoc" do
  include_examples "ApiHelper"

  it "should set user's db document by doc key and data" do
    data = {'1' => {'foo' => 'bar'}}
    dockey = 'myuserdoc'
    sdocname = @s2.docname(dockey)

    post "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{@s2.name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result(sdocname => data)
  end

  it "should append data to the user's db document by doc name and data" do
    data = {'1' => {'foo' => 'bar'}}
    data2 = {'2' => {'foo1' => 'bar1'}}
    data3 = data.merge(data2)
    dockey = 'abc:abc'
    sdocname = @s2.docname(dockey)
    post "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{@s2.name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result(sdocname => data)

    post "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{@s2.name}/docs/#{dockey}", {:data => data2, :append => true}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_result(sdocname => data3)
  end

  it "should error out in ateempt to set a db doc for a non-existent user" do
    data = {'1' => {'foo' => 'bar'}}
    data2 = {'2' => {'foo1' => 'bar1'}}
    data3 = data.merge(data2)
    dockey = 'abc:abc'
    sdocname = @s2.docname(dockey)
    post "/rc/#{Rhoconnect::API_VERSION}/users/invalid_user/sources/#{@s2.name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.status.should == 500
    last_response.should_not be_ok
  end
end