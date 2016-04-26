require File.join(File.dirname(__FILE__),'spec_helper')

describe "Node" do
  include Rhoconnect
  include TestHelpers

  before(:each) do
    Store.create
    Store.flush_all
    Rhoconnect.use_node = true
  end

  after(:each) do
    Rhoconnect::Node.kill_process
  end

  it "should start node" do
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect::Node.started.should == true
  end

  it "should stop node" do
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect::Node.started.should == true
    Rhoconnect::Node.kill_process
    Rhoconnect::Node.started.should == false
  end

  it "should print message if `package.json` not detected" do
    File.stub(:exists?).and_return(false)
    Rhoconnect::Node.should_receive(:log).once.with("No `package.json` detected, disabling JavaScript support.")
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect::Node.started.should == false
  end

  it "should print message if node not detected" do
    File.stub(:executable?).and_return(false)
    Rhoconnect::Node.should_receive(:log).once.with("Node.js not detected, disabling JavaScript support.")
    Rhoconnect.bootstrap(get_testapp_path)
    Rhoconnect::Node.started.should == false
  end
end