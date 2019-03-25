require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'PingJob' do
  include_examples 'SharedRhoconnectHelper', :rhoconnect_data => true

  before(:each) do
    @u1_fields = {:login => 'testuser1'}
    @u1 = User.create(@u1_fields)
    @u1.password = 'testpass1'
    @c1_fields = {
        :device_type => 'Apple',
        :device_pin => 'abcde',
        :device_port => '3333',
        :user_id => @u1.id,
        :app_id => @a.id
    }
    @c1 = Client.create(@c1_fields, {:source_name => @s_fields[:name]})
    @a.users << @u1.id
  end

  it 'should perform apple ping with integer parameters' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => 5,
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil, }

    scrubbed_params = params.dup
    scrubbed_params['vibrate'] = '5'

    Apple.should_receive(:ping).once.with({'device_pin' => @c.device_pin,
                                           'device_port' => @c.device_port}.merge!(scrubbed_params))
    PingJob.perform(params)
  end

  it 'should perform apple ping' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil}
    Apple.should_receive(:ping).once.with({'device_pin' => @c.device_pin,
                                           'device_port' => @c.device_port}.merge!(params))
    PingJob.perform(params)
  end

  it 'should skip ping for the unknown platform' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil}
    @c.device_type = 'unknown_device_type'
    PingJob.should_receive(:log).once.with("Dropping ping request for unsupported platform '#{@c.device_type}'")
    PingJob.perform(params)
  end

  it 'should skip ping for empty device_type' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'device_app_id' => nil,
              'device_app_version' => nil}
    @c.device_type = nil
    PingJob.should_receive(:log).once.with("Skipping ping for non-registered client_id '#{@c.id}'...")
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should skip ping for empty device_pin' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c.device_type = 'Android'
    @c.device_pin = nil
    PingJob.should_receive(:log).once.with("Skipping ping for non-registered client_id '#{@c.id}'...")
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should drop ping if it\'s already in user\'s device pin list' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil}
    # another client with the same device pin ...
    @c_fields.delete(:id)
    @c1 = Client.create(@c_fields, {:source_name => @s_fields[:name]})
    # and yet another one ...
    @c_fields.delete(:id)
    @c2 = Client.create(@c_fields, {:source_name => @s_fields[:name]})

    Apple.should_receive(:ping).with({'device_pin' => @c.device_pin, 'device_port' => @c.device_port}.merge!(params))
    PingJob.should_receive(:log).twice.with(/Dropping ping request for client/)
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should drop ping if it\'s already in user\'s phone id list and device pin is different' do
    params = {'user_id' => @u.id,
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c.phone_id = '3'
    @c_fields.merge!(:phone_id => '3')
    # another client with the same phone id..
    @c_fields.delete(:id)
    @c1 = Client.create(@c_fields, {:source_name => @s_fields[:name]})
    #  yet another...
    @c_fields.delete(:id)
    @c2 = Client.create(@c_fields, {:source_name => @s_fields[:name]})

    Apple.should_receive(:ping).with({'device_pin' => @c.device_pin, 'phone_id' => @c.phone_id, 'device_port' => @c.device_port}.merge!(params))
    PingJob.should_receive(:log).twice.with(/Dropping ping request for client/)
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should ping two different users from two different devices - Apple and GCM' do
    params = {'user_id' => [@u.id, @u1.id],
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c.phone_id = '3'

    scrubbed_params = params.dup
    scrubbed_params['vibrate'] = '5'
    @c1.device_push_type = 'Gcm'

    Apple.should_receive(:ping).with(params.merge!({'device_pin' => @c.device_pin, 'phone_id' => @c.phone_id, 'device_port' => @c.device_port}))
    Gcm.should_receive(:ping).with({'device_pin' => @c1.device_pin, 'device_port' => @c1.device_port}.merge!(scrubbed_params))
    PingJob.perform(params)
  end

  it 'should drop ping with two different users from the same device' do
    params = {'user_id' => [@u.id, @u1.id],
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c.phone_id = '3'
    @c1.phone_id = '3'

    Apple.should_receive(:ping).with({'device_pin' => @c.device_pin, 'phone_id' => @c.phone_id, 'device_port' => @c.device_port}.merge!(params))
    PingJob.should_receive(:log).once.with(/Dropping ping request for client/)
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should drop ping with two different users with the same pin' do
    params = {'user_id' => [@u.id, @u1.id],
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'phone_id' => nil,
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c1.device_pin = @c.device_pin

    Apple.should_receive(:ping).with({'device_pin' => @c.device_pin, 'device_port' => @c.device_port}.merge!(params))
    PingJob.should_receive(:log).once.with(/Dropping ping request for client/)
    lambda {PingJob.perform(params)}.should_not raise_error
  end

  it 'should process all pings even if some of them are failing' do
    params = {'user_id' => [@u.id, @u1.id],
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil, }
    @c.phone_id = '3'

    scrubbed_params = params.dup
    scrubbed_params['vibrate'] = '5'
    @c1.device_push_type = 'Gcm'

    params.merge!({'device_pin' => @c.device_pin, 'phone_id' => @c.phone_id, 'device_port' => @c.device_port})
    allow(Apple).to receive(:ping).with(params).and_raise(SocketError.new("Socket failure"))
    allow(Gcm).to receive(:ping).with({'device_pin' => @c1.device_pin, 'device_port' => @c1.device_port}.merge!(scrubbed_params))
    exception_raised = false
    begin
      PingJob.perform(params)
    rescue Exception => e
      exception_raised = true
    end
    exception_raised.should == true
  end

  it 'should skip ping for unknown user or user with no clients' do
    params = {'user_id' => ['fake_user'],
              'api_token' => @api_token,
              'sources' => [@s.name],
              'message' => 'hello world',
              'vibrate' => '5',
              'badge' => '5',
              'sound' => 'hello.mp3',
              'phone_id' => nil,
              'device_app_id' => nil,
              'device_app_version' => nil, }
    PingJob.should_receive(:log).once.with(/Skipping ping for unknown user 'fake_user' or 'fake_user' has no registered clients.../)
    PingJob.perform(params)
  end

  it 'should process ping for device_push_type if available' do
    @c.device_push_type = 'rhoconnect_push'
    @c.device_port = nil
    params = {
        'user_id' => @u.id,
        'message' => 'hello world',
        'device_port' => '',
        'vibrate' => '',
        'phone_id' => nil,
        'device_app_id' => nil,
        'device_app_version' => nil,
    }
    scrubbed_params = params.dup

    RhoconnectPush.should_receive(:ping).once.with(
        {'device_pin' => @c.device_pin}.merge!(scrubbed_params)
    )
    PingJob.perform(params)
  end
end
