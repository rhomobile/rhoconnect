require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiDeleteClient" do
  include_examples "ApiHelper"

  it "should delete client for the user" do
    delete "/rc/#{Rhoconnect::API_VERSION}/users/#{@u_fields[:login]}/clients/#{@c.id}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    Client.is_exist?(@c.id).should == false
    User.load(@u_fields[:login]).clients.members.should == []
  end
end