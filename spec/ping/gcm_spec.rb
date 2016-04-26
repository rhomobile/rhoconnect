require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Android GCM" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before(:each) do
    @params = {"device_pin" => @c.device_pin,
      "sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @response = double('response')
    Rhoconnect.settings[:gcm_api_key] = 'validkey'
  end

  it "should ping gcm successfully" do
    result = 'id=0:34234234134254%abc123\n'
    @response.stub(:code).and_return(200)
    @response.stub(:body).and_return(result)
    @response.stub(:headers).and_return({})
    @response.stub(:return!).and_return(@response)
    setup_post_yield(@response)
    Gcm.ping(@params).body.should == result
  end

  it "should raise error on missing gcm_api_key setting" do
    key = Rhoconnect.settings[:gcm_api_key].dup
    Rhoconnect.settings[:gcm_api_key] = nil
    lambda { Gcm.ping(@params) }.should raise_error(
      Gcm::InvalidApiKey, 'Missing `:gcm_api_key:` option in settings/settings.yml'
    )
    Rhoconnect.settings[:gcm_api_key] = key
  end

  it "should ping gcm with 503 connection error" do
    error = 'Connection refused'
    @response.stub(:body).and_return(error)
    RestClient.stub(:post).and_return { raise RestClient::Exception.new(@response,503) }
    Gcm.should_receive(:log).twice
    lambda { Gcm.ping(@params) }.should raise_error(RestClient::Exception)
  end

  it "should ping gcm with 200 error message" do
    error = 'Error=QuotaExceeded'
    @response.stub(:code).and_return(200)
    @response.stub(:body).and_return(error)
    @response.stub(:headers).and_return(nil)
    setup_post_yield(@response)
    Gcm.should_receive(:log).twice
    lambda { Gcm.ping(@params) }.should raise_error(Gcm::GCMPingError, "GCM ping error: QuotaExceeded")
  end

  it "should fail to ping with bad authentication" do
    error = 'Error=BadAuthentication'
    @response.stub(:code).and_return(403)
    @response.stub(:body).and_return(error)
    @response.stub(:headers).and_return({})
    setup_post_yield(@response)
    Gcm.should_receive(:log).twice
    lambda { Gcm.ping(@params) }.should raise_error(
      Gcm::InvalidApiKey, "Invalid GCM api key. Obtain new api key from GCM service."
    )
  end

  it "should ping gcm with 401 error message" do
    @response.stub(:code).and_return(401)
    @response.stub(:body).and_return('')
    setup_post_yield(@response)
    Gcm.should_receive(:log).twice
    lambda { Gcm.ping(@params) }.should raise_error(
      Gcm::InvalidApiKey, "Invalid GCM api key. Obtain new api key from GCM service."
    )
  end

  it "should compute gcm_message" do
    expected = {
      'registration_ids' => [@c.device_pin],
      'collapse_key' => "RAND_KEY",
      'data' => {
        'do_sync' => @s.name,
        'alert' => "hello world",
        'vibrate' => '5',
        'sound' => "hello.mp3"
      }
    }
    actual = Gcm.gcm_message(@params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end

  it "should trim empty or nil params from gcm_message" do
    expected = {'registration_ids' => [@c.device_pin], 'collapse_key' => "RAND_KEY",
      'data' => {'vibrate' => '5', 'do_sync' => '', 'sound' => "hello.mp3"} }
    params = {"device_pin" => @c.device_pin,
      "sources" => [], "message" => '', "vibrate" => '5', "sound" => 'hello.mp3'}
    actual = Gcm.gcm_message(params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end
end
