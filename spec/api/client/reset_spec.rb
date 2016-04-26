require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiClientReset" do
  include_examples "ApiHelper"

  before(:each) do
    do_post "/rc/#{Rhoconnect::API_VERSION}/app/login",  "login" => @u.login, "password" => 'testpass'
  end

  it "should handle client reset" do
    set_doc_state(@c, :cd => @data)
    post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/reset"
    last_response.should be_ok
    verify_doc_result(@c, :cd => {})
    Client.load(@c.id,{:source_name => @s.name}).should_not be_nil
  end

  it "should handle client reset on individual source adapters" do
    @c.source_name = 'SampleAdapter'
    set_doc_state(@c, :cd => @data)
    verify_doc_result(@c, :cd => @data)

    @c.source_name = 'SimpleAdapter'
    set_doc_state(@c, :cd => @data)
    verify_doc_result(@c, :cd => @data)

    sources = [{'name'=>'SimpleAdapter'}]
    do_post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/reset", {:sources => sources}
    last_response.should be_ok

    @c.source_name = 'SampleAdapter'
    verify_doc_result(@c, :cd => @data)
    @c.source_name = 'SimpleAdapter'
    verify_doc_result(@c, :cd => {})
  end
end