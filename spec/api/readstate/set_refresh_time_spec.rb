require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiSetRefreshTime" do
  include_examples "ApiHelper"

  it "should set refresh time to 100s from 'now'" do
    before = Time.now.to_i
    put "/rc/#{Rhoconnect::API_VERSION}/readstate/users/#{@u_fields[:login]}/sources/#{@s_fields[:name]}",
      {:refresh_time => 100}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    after = Time.now.to_i
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.read_state.refresh_time.should >= before + 100
    @s.read_state.refresh_time.should <= after + 100
  end

  it "should set refresh time to 'now' if no refresh_time provided" do
    before = Time.now.to_i
    put "/rc/#{Rhoconnect::API_VERSION}/readstate/users/#{@u_fields[:login]}/sources/#{@s_fields[:name]}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    after = Time.now.to_i
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.read_state.refresh_time.should >= before
    @s.read_state.refresh_time.should <= after
  end

  it "should set poll interval" do
    put "/rc/#{Rhoconnect::API_VERSION}/readstate/users/#{@u_fields[:login]}/sources/#{@s_fields[:name]}", {:poll_interval => 100}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.poll_interval.should == 100
  end

  it "should should not set nil poll interval with old route and deprecation warning" do
    post "/api/set_refresh_time", :api_token => @api_token,
      :source_name => @s_fields[:name], :user_name => @u_fields[:login], :poll_interval => nil
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    @s = Source.load(@s.id,@s_params)
    @s.poll_interval.should == 300
  end

  it "should should not set nil poll interval" do
    put "/rc/#{Rhoconnect::API_VERSION}/readstate/users/#{@u_fields[:login]}/sources/#{@s_fields[:name]}", {:poll_interval => nil}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.poll_interval.should == 300
  end
end