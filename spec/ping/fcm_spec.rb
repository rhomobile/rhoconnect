require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Ping Android FCM" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before(:each) do
    allow( Google::Auth).to receive(:get_application_default)
    @params = {"device_pin" => @c.device_pin,
               "sources" => [@s.name], "message" => 'hello world',
               "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @response = double('response')
    Rhoconnect.settings[:fcm_project_id] = 'valid_project_id'
    Rhoconnect.settings[:package_name] = 'valid_package_name'
  end

  it "should ping fcm successfully" do
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/valid_project_id/messages:send").with { |request|
      hash = JSON.parse request.body
      valid = hash["message"]["token"] == "abcd"
      valid = valid && hash["message"]["topic"] == nil
      valid = valid && hash["message"]["android"]["restricted_package_name"] == "valid_package_name"
      valid
    }
    Fcm.ping(@params)
  end

  it "should raise error on missing fcm_project_id setting" do
    key = Rhoconnect.settings[:fcm_project_id.dup]
    Rhoconnect.settings[:fcm_project_id] = nil
    expect(lambda { Fcm.ping(@params) }).to raise_error(Fcm::InvalidProjectId, 'Missing `:fcm_project_id:` option in settings/settings.yml')
    Rhoconnect.settings[:fcm_project_id] = key
  end

  it "should raise error on missing package_name setting" do
    key = Rhoconnect.settings[:package_name.dup]
    Rhoconnect.settings[:package_name] = nil
    expect(lambda { Fcm.ping(@params) }).to raise_error(Fcm::InvalidPackageName, 'Missing `:package_name:` option in settings/settings.yml')
    Rhoconnect.settings[:package_name] = key
  end

  it "should ping fcm with 503 connection error" do
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/valid_project_id/messages:send").to_raise(RestClient::Exception.new(nil,503))
    expect(lambda { Fcm.ping(@params) }).to raise_error(RestClient::Exception)
  end

  xit "should ping fcm with 200 error message" do
    allow( Google::Auth).to receive(:get_application_default)

    error = 'error:DeviceMessageRateExceeded'
    allow(@response).to receive(:code).and_return(200)
    allow(@response).to receive(:body).and_return(error)
    allow(@response).to receive(:headers).and_return(nil)
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/valid_project_id/messages:send").to_raise(RestClient::Exception.new(@response,200))
    expect(lambda { Fcm.ping(@params) }).to raise_error(Fcm::FCMPingError, "FCM ping error: DeviceMessageRateExceeded")
  end

  xit "should fail to ping with bad authentication" do
    error = 'Error=BadAuthentication'
    allow(@response).to receive(:code).and_return(403)
    allow(@response).to receive(:body).and_return(error)
    allow(@response).to receive(:headers).and_return({})
    setup_post_yield(@response)
    expect(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to raise_error(
                                                Fcm::InvalidProjectId, "Invalid FCM project id. Obtain new api key from FCM service."
                                            )
  end

  xit "should ping fcm with 401 error message" do
    allow(@response).to receive(:code).and_return(401)
    allow(@response).to receive(:body).and_return('')
    setup_post_yield(@response)
    expect(Fcm).to receive(:log).twice
    expect(lambda { Fcm.ping(@params) }).to raise_error(
                                                Fcm::InvalidProjectId, "Invalid FCM project id. Obtain new api key from FCM service."
                                            )
  end

  it "should compute fcm_message" do
    expect(Google::Apis::Messages::Message).to receive(:new) do |options|
      expect(options[:token]).to eq(@c.device_pin)
      expect(options[:android]["priority"]).to eq("high")
      expect(options[:android]["restricted_package_name"]).to eq(Rhoconnect.settings[:package_name])
      expect(options[:android]["data"]["do_sync"]).to eq(@s.name)
      expect(options[:android]["data"]["alert"]).to eq("hello world")
      expect(options[:android]["data"]["vibrate"]).to eq("5")
      expect(options[:android]["data"]["sound"]).to eq("hello.mp3")
      expect(options[:android]["notification"]["body"]).to eq("hello world")
    end

    Fcm.fcm_message(Rhoconnect.settings[:package_name], @params)
  end

  it "should trim empty or nil params from fcm_message" do
    expect(Google::Apis::Messages::Message).to receive(:new) do |options|
      expect(options[:token]).to eq(@c.device_pin)
      expect(options[:android]["priority"]).to eq("high")
      expect(options[:android]["restricted_package_name"]).to eq(Rhoconnect.settings[:package_name])
      expect(options[:android]["data"]["do_sync"]).to eq('')
      expect(options[:android]["data"]["alert"]).to eq(nil)
      expect(options[:android]["data"]["vibrate"]).to eq("5")
      expect(options[:android]["data"]["sound"]).to eq("hello.mp3")
      expect(options[:android]["notification"]["body"]).to eq(nil)
    end

    params = {
        "device_pin" => @c.device_pin,
        "sources" => [],
        "message" => '',
        "vibrate" => '5',
        "sound" => 'hello.mp3'
    }

    Fcm.fcm_message(Rhoconnect.settings[:package_name], params)
  end
end
