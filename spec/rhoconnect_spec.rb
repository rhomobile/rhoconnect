require File.join(File.dirname(__FILE__),'spec_helper')

describe "Rhoconnect" do
  include TestHelpers
  let(:test_app_name) { 'application' }

  before(:each) do
    Store.create
    Store.flush_all
  end

  it "should bootstrap Rhoconnect with block" do
    Rhoconnect.bootstrap(get_testapp_path) do |rhoconnect|
      rhoconnect.vendor_directory = 'foo'
    end
    path = get_testapp_path
    File.expand_path(Rhoconnect.base_directory).should == path
    File.expand_path(Rhoconnect.app_directory).should == path
    File.expand_path(Rhoconnect.data_directory).should == File.join(path,'data')
    Rhoconnect.vendor_directory.should == 'foo'
    Rhoconnect.bulk_sync_poll_interval.should == 3600
    Rhoconnect.environment.should == :test
    Rhoconnect.stats.should == false
    Rhoconnect.cookie_expire.should == 9999999
    App.is_exist?(test_app_name).should be_true
  end

  it "should bootstrap Rhoconnect with RHO_ENV provided" do
    ENV['RHO_ENV'] = 'production'
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect.environment.should == :production
    ENV.delete('RHO_ENV')
  end

  it "should bootstrap Rhoconnect with RACK_ENV provided" do
    env = ENV['RACK_ENV'].dup
    ENV['RACK_ENV'] = 'production'
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect.environment.should == :production
    ENV['RACK_ENV'] = env
  end

  it "should bootstrap with existing app" do
    app = App.create(:name => test_app_name)
    App.should_receive(:load).once.with(test_app_name).and_return(app)
    Rhoconnect.bootstrap(get_testapp_path)
  end

  it "should bootstrap app with no sources" do
    App.create(:name => test_app_name).delete
    Rhoconnect.bootstrap(get_emptyapp_path)
    App.load(test_app_name).sources.should == []
  end

  it "should exit if schema config exists" do
    config = Rhoconnect.get_config(get_testapp_path)
    config[:sources]['FixedSchemaAdapter'].merge!(
      'schema' => {'property' => 'foo'}
    )
    Rhoconnect.stub(:get_config).and_return(config)
    Rhoconnect.should_receive(:log).once.with(
      "ERROR: 'schema' field in settings.yml is not supported anymore, please use source adapter schema method!"
    )
    lambda { Rhoconnect.bootstrap(get_testapp_path) }.should raise_error(SystemExit)
  end

  it "should add associations during bootstrap" do
    Rhoconnect.bootstrap(get_testapp_path)
    s = Source.load('SampleAdapter',{:app_id => test_app_name,:user_id => '*'})
    s.has_many.should == "FixedSchemaAdapter,brand"
  end
end