require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Apple" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before do
    @params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world',
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3',
      "device_pin" => @c.device_pin, "device_port" => @c.device_port}
    ssl_ctx = double("ssl_ctx")
    allow(ssl_ctx).to receive(:key=).and_return('key')
    allow(ssl_ctx).to receive(:cert=).and_return('cert')
    allow(OpenSSL::SSL::SSLContext).to receive(:new).and_return(ssl_ctx)
    allow(OpenSSL::PKey::RSA).to receive(:new)
    allow(OpenSSL::X509::Certificate).to receive(:new)

    tcp_socket = double("tcp_socket")
    allow(tcp_socket).to receive(:close)
    allow(TCPSocket).to receive(:new).and_return(tcp_socket)

    @ssl_socket = double("ssl_socket")
    allow(@ssl_socket).to receive(:sync=)
    allow(@ssl_socket).to receive(:connect)
    allow(@ssl_socket).to receive(:write)
    allow(@ssl_socket).to receive(:close)
    allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(@ssl_socket)
  end

  # TODO: This should really test SSLSocket.write
  it "should ping apple" do
    Apple.ping(@params)
  end

  it "should log deprecation on iphone ping" do
    expect(Iphone).to receive(:log).once.with("DEPRECATION WARNING: 'iphone' is a deprecated device_type, use 'apple' instead")
    Iphone.ping(@params)
  end

  it "should compute apn_message" do
    expected_hash = {
      "aps"=>{"vibrate"=>"5", "badge"=>5, "alert"=>"hello world", "sound"=>"hello.mp3"},
      "do_sync"=>["SampleAdapter"]
    }
    apn_message = Apple.apn_message(@params)
    expect(apn_message[0, 7].inspect.gsub("\"", "")).to  eq("\\x00\\x00 \\xAB\\xCD\\x00g")
    expect(JSON.parse(apn_message[7, apn_message.length])).to eq(expected_hash)
  end

  it "should compute apn_message with source array" do
    @params['sources'] << 'SimpleAdapter'
    expected_hash = {
      "aps"=>{"vibrate"=>"5", "badge"=>5, "alert"=>"hello world", "sound"=>"hello.mp3"},
      "do_sync"=>["SampleAdapter", "SimpleAdapter"]
    }
    apn_message = Apple.apn_message(@params)
    expect(apn_message[0, 7].inspect.gsub("\"", "")).to eq("\\x00\\x00 \\xAB\\xCD\\x00w")
    expect(JSON.parse(apn_message[7, apn_message.length])).to eq(expected_hash)
  end

  it "should raise SocketError if socket fails" do
    error = 'socket error'
    allow(@ssl_socket).to receive(:write).and_raise(SocketError.new(error))
    expect(Apple).to receive(:log).once.with("Error while sending ping: #{error}")
    expect(lambda { Apple.ping(@params) }).to raise_error(SocketError, error)
  end

  it "should do nothing if no cert or host or port" do
     allow(Rhoconnect::Apple).to receive(:get_config).and_return({:test => {:iphonecertfile=>"none"}})
     expect(Rhoconnect::Apple).to receive(:get_config).once
     expect(OpenSSL::SSL::SSLContext).to receive(:new).exactly(0).times
     Apple.ping(@params)
  end
end
