require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiListSourceDocs" do
  include_examples "ApiHelper"

  it "should list of shared source documents" do
    sourcename = "SimpleAdapter"
    user_id = '*'
    get "/rc/#{Rhoconnect::API_VERSION}/users/#{user_id}/sources/#{sourcename}/docnames", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == {
      "md"=>"source:application:__shared__:SimpleAdapter:md",
      "errors"=>"source:application:__shared__:SimpleAdapter:errors",
      "md_size"=>"source:application:__shared__:SimpleAdapter:md_size",
      "md_copy"=>"source:application:__shared__:SimpleAdapter:md_copy"}
  end

  it "should list of shared source documents with old route and deprecation warning" do
    post "/api/list_source_docs", {:source_id => "SimpleAdapter", :user_id => '*'}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == {
      "md"=>"source:application:__shared__:SimpleAdapter:md",
      "errors"=>"source:application:__shared__:SimpleAdapter:errors",
      "md_size"=>"source:application:__shared__:SimpleAdapter:md_size",
      "md_copy"=>"source:application:__shared__:SimpleAdapter:md_copy"}
  end

  it "should list user source documents" do
    sourcename = "SampleAdapter"
    get "/rc/#{Rhoconnect::API_VERSION}/users/#{@u.id}/sources/#{sourcename}/docnames", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == {
      "md"=>"source:application:testuser:SampleAdapter:md",
      "errors"=>"source:application:testuser:SampleAdapter:errors",
      "md_size"=>"source:application:testuser:SampleAdapter:md_size",
      "md_copy"=>"source:application:testuser:SampleAdapter:md_copy"}
  end
end