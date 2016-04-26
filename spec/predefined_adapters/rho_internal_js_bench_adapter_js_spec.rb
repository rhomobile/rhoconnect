require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

describe "Rhoconnect::RhoInternalJsBenchAdapter" do
  include Rhoconnect
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :secret, "secure!"
    Rhoconnect.use_node = true
    Rhoconnect.bootstrap(get_testapp_path)
  end

  def app
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  after(:each) do
    Rhoconnect::Store.flush_all
    Rhoconnect::Node.kill_process
    #Source.valid_doctypes.delete('tmpdoc'.to_sym)
  end

  it "should call login method from model" do
    rho_int = RhoInternalJsBenchAdapter.new(Source.load('RhoInternalJsBenchAdapter', {:app_id => @a.id, :user_id => @u.id}))
    res = rho_int.login
    res.should == true
  end

  it "should call logoff method from model" do
    rho_int = RhoInternalJsBenchAdapter.new(Source.load('RhoInternalJsBenchAdapter', {:app_id => @a.id, :user_id => @u.id}))
    res = rho_int.logoff
    res.should == true
  end

  it "should call query method from model" do
    rho_int = RhoInternalJsBenchAdapter.new(Source.load('RhoInternalJsBenchAdapter', {:app_id => @a.id, :user_id => @u.id}))
    res = rho_int.query
    res.should == true
  end
end