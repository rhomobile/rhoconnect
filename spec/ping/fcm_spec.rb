require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Android FCM" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before(:each) do
    @params = {"device_pin" => @c.device_pin,
      "sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @response = double('response')
    Rhoconnect.settings[:fcm_api_key] = 'validkey'
  end

  it "should ping fcm successfully" do
    result = 'id=0:34234234134254%abc123\n'
    allow(@response).to receive(:code).and_return(200)
    allow(@response).to receive(:body).and_return(result)
    allow(@response).to receive(:headers).and_return({})
    allow(@response).to receive(:return!).and_return(@response)
    setup_post_yield(@response)
    expect(Gcm.ping(@params).body).to eq(result)
  end

  it "should raise error on missing fcm_project_id setting" do
    key = Rhoconnect.settings[:fcm_project_id.dup
    Rhoconnect.settings[:fcm_project_id = nil
    expect(lambda { Fcm.ping(@params) }).to raise_error(Gcm::InvalidProjectId, 'Missing `:fcm_project_id:` option in settings/settings.yml')
    Rhoconnect.settings[:fcm_project_id = key
  end

  it "should ping fcm with 503 connection error" do
    error = 'Connection refused'
    allow(@response).to receive(:body).and_return(error)
    allow(RestClient).to receive(:post).and_raise(RestClient::Exception.new(@response,503))
    allow(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to raise_error(RestClient::Exception)
  end

  it "should ping fcm with 200 error message" do
    error = 'Error=QuotaExceeded'
    allow(@response).to receive(:code).and_return(200)
    allow(@response).to receive(:body).and_return(error)
    allow(@response).to receive(:headers).and_return(nil)
    setup_post_yield(@response)
    expect(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to raise_error(Fcm::FCMPingError, "FCM ping error: QuotaExceeded")
  end

  it "should fail to ping with bad authentication" do
    error = 'Error=BadAuthentication'
    allow(@response).to receive(:code).and_return(403)
    allow(@response).to receive(:body).and_return(error)
    allow(@response).to receive(:headers).and_return({})
    setup_post_yield(@response)
    expect(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to  raise_error(
      Fcm::InvalidProjectId, "Invalid FCM project id. Obtain new api key from FCM service."
    )
  end

  it "should ping fcm with 401 error message" do
    allow(@response).to receive(:code).and_return(401)
    allow(@response).to receive(:body).and_return('')
    setup_post_yield(@response)
    expect(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to raise_error(
      Fcm::InvalidProjectId, "Invalid FCM project id. Obtain new api key from FCM service."
    )
  end

  it "should compute fcm_message" do
    expected = {
      'registration_ids' => [@c.device_pin],
      'data' => {
        'do_sync' => @s.name,
        'alert' => "hello world",
        'vibrate' => '5',
        'sound' => "hello.mp3"
      }
    }
    actual = Fcm.gcm_message(@params)
    expect(actual).to eq(expected)
  end

  it "should trim empty or nil params from fcm_message" do
    expected = {'registration_ids' => [@c.device_pin],
      'data' => {'vibrate' => '5', 'do_sync' => '', 'sound' => "hello.mp3"} }
    params = {"device_pin" => @c.device_pin,
      "sources" => [], "message" => '', "vibrate" => '5', "sound" => 'hello.mp3'}
    actual = Fcm.gcm_message(params)
    expect(actual).to eq(expected)
  end
end
