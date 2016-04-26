require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping using RhoConnect push" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before do
    @params = {"device_pin" => @c.device_pin,
      "sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @response = double('response')

  end

  it "should ping rhoconnect push successfully" do
    result = ''
    @response.stub(:code).and_return(204)
    @response.stub(:body).and_return(result)
    @response.stub(:return!).and_return(@response)
    RestClient.stub(:post).and_return(@response)
    res = RhoconnectPush.ping(@params)
    res.body.should == result
    res.code.should == 204
  end

  it "should ping rhoconnect push with missing push_server property" do
    RhoconnectPush.stub(:get_config).and_return({:test => {}})
    lambda { RhoconnectPush.ping(@params) }.should raise_error(
      RhoconnectPush::InvalidPushServer, "Missing or invalid `:push_server` in settings/settings.yml."
    )
  end


  it "should ping rhoconnect push with 400 response" do
    result = ''
    @response.stub(:code).and_return(400)
    @response.stub(:body).and_return(result)
    @response.stub(:return!).and_return(@response)
    setup_post_yield(@response)
    lambda { RhoconnectPush.ping(@params) }.should raise_error(
      RhoconnectPush::InvalidPushRequest, "Invalid push request."
    )
  end

  it "should compute push_message" do
    expected = {
      'collapseId' => 5,
      'data' => {
        'do_sync' => [@s.name],
        'alert' => "hello world",
        'vibrate' => '5',
        'sound' => "hello.mp3"
      }
    }
    actual = RhoconnectPush.push_message(@params)
    JSON.parse(actual).should == expected
  end
end
