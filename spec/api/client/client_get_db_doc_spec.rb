require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiClientGetDbDoc" do
  include_examples "ApiHelper"

  it "should get clients's db document by doc key and data" do
    data = {'1' => {'foo' => 'bar'}}
    Client.define_valid_doctypes([:myclientdoc])
    dockey = 'myclientdoc'
    post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{@c.source_name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    get "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{@c.source_name}/docs/#{dockey}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    JSON.parse(last_response.body).should == data
    Client.valid_doctypes.delete(dockey.to_sym)
  end

  it "should append data to the client's db document by doc name and data" do
    data = {'1' => {'foo' => 'bar'}}
    data2 = {'2' => {'foo1' => 'bar1'}}
    data3 = data.merge(data2)
    dockey = 'abc:abc'
    Client.define_valid_doctypes([dockey])
    post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{@c.source_name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@c, dockey => data)

    post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{@c.source_name}/docs/#{dockey}", {:data => data2, :append => true}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@c, dockey => data3)
    Client.valid_doctypes.delete(dockey.to_sym)
  end
end