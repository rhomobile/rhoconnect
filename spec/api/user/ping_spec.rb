require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiPing" do
  include_examples "ApiHelper"

  it "should do ping synchronously" do
    params = {"user_id" => @u.id, "sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    PingJob.should respond_to :perform
    PingJob.should_receive(:perform).once.with(params)
    post "/rc/#{Rhoconnect::API_VERSION}/users/ping", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
  end

  it "should do ping asynchronously" do
    params = {"user_id" => @u.id, "async" => "true","sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}

    PingJob.should respond_to :enqueue
    PingJob.should_receive(:enqueue).once.with(params)
    post "/rc/#{Rhoconnect::API_VERSION}/users/ping", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
  end
end