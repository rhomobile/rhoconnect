require File.join(File.dirname(__FILE__),'spec_helper')

describe "ApiToken" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  it "should generate api token with user" do
    token = ApiToken.create(:user_id => @u.id)
    token.value.length.should == 32
    token.user_id.should == @u.id
    token.user.login.should == @u.login
    token.delete
  end
end
