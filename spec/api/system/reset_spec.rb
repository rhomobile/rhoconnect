require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiReset" do
  include_examples "ApiHelper"

  it "should reset and re-create rhoadmin user with bootstrap" do
    Store.put_data('somedoc',{ '1' => {'foo'=>'bar'}})
    post "/rc/#{Rhoconnect::API_VERSION}/system/reset", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    App.is_exist?(test_app_name).should == true
    Store.get_data('somedoc').should == {}
    User.authenticate('rhoadmin','').should_not be_nil
  end

  it "should reset and re-create rhoadmin user with initializer" do
    Store.put_data('somedoc',{ '1' => {'foo'=>'bar'}})
    post "/rc/#{Rhoconnect::API_VERSION}/system/reset", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    App.is_exist?(test_app_name).should == true
    Store.get_data('somedoc').should == {}
    User.authenticate('rhoadmin','').should_not be_nil
  end
end
