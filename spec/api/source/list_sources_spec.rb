require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiListSources" do
  include_examples "ApiHelper"

  it "should list all application sources using partition_type param" do
    get "/rc/#{Rhoconnect::API_VERSION}/sources/type/all", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).sort.should == ["SimpleAdapter", "SampleAdapter", "FixedSchemaAdapter", "OtherAdapter", "JsSample"].sort
  end

  it "should list app partition sources" do
    get "/rc/#{Rhoconnect::API_VERSION}/sources/type/app", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).sort.should == ["SimpleAdapter", "OtherAdapter"].sort
  end

  it "should list user partition sources" do
    get "/rc/#{Rhoconnect::API_VERSION}/sources/type/user", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).sort.should == ["SampleAdapter", "FixedSchemaAdapter", "JsSample"].sort
  end
end