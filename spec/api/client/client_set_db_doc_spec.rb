require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiClientSetDbDoc" do
  include_examples "ApiHelper"

  it "should set client's db document by doc key and data" do
    data = {'1' => {'foo' => 'bar'}}
    dockey = 'myclientdoc'
    Client.define_valid_doctypes([dockey])
    post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{@c.source_name}/docs/#{dockey}", {:data => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@c, dockey => data)
    Client.valid_doctypes.delete(dockey.to_sym)
  end
end