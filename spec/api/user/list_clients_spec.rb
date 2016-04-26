require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiListUserClients" do
  include_examples "ApiHelper"

  it "should list user's clients" do
    get "/rc/#{Rhoconnect::API_VERSION}/users/#{@u_fields[:login]}/clients", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    res = JSON.parse(last_response.body)
    res.is_a?(Array).should == true
    res.size.should == 1
    res[0].is_a?(String) == true
    res[0].length.should == 32
  end

  it "should list user's clients with old route and show deprecation warning" do
    post "/api/list_clients", {:api_token => @api_token,
      :user_id => @u_fields[:login]}
    res = JSON.parse(last_response.body)
    res.is_a?(Array).should == true
    res.size.should == 1
    res[0].is_a?(String) == true
    res[0].length.should == 32
  end

  it "should handle empty client's list" do
    @u.clients.delete(@c.id)
    get "/rc/#{Rhoconnect::API_VERSION}/users/#{@u_fields[:login]}/clients", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == []
  end
end