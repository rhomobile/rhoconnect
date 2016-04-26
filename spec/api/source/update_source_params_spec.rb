require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiUpdateSourceParams" do
  include_examples "ApiHelper"

  it "should set poll_interval to 99 seconds" do
    @s1 = Source.load(@s.id,@s_params)
    before = @s1.poll_interval.to_i
    put "/rc/#{Rhoconnect::API_VERSION}/sources/#{@s_fields[:name]}",
      {:data => {:poll_interval => 99}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    @s2 = Source.load(@s.id,@s_params)
    after = @s2.poll_interval
    before.should == 300
    after.should == 99
  end

  it "should fail to update the source if param is not found" do
    put "/rc/#{Rhoconnect::API_VERSION}/sources/#{@s_fields[:name]}",
      {:data => {:invalid_param => "invalid_data"}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
      last_response.status.should == 500
      last_response.body.match('undefined method').should_not be_nil
  end
end