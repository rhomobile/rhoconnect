require File.join(File.dirname(__FILE__),'spec_helper')

describe "App" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  it "should create app with fields" do
    @a.id.should == @a_fields[:name]
    @a1 = App.load(@a_fields[:name])
    @a1.id.should == @a.id
    @a1.name.should == @a_fields[:name]
  end

  it "should add source adapters" do
    @a1 = App.load(@a_fields[:name])
    @a1.sources.sort.should == ["FixedSchemaAdapter", "JsSample", "OtherAdapter", "SampleAdapter", "SimpleAdapter"]
  end

  it "should force environment default and override setting" do
    poll_interval_default = Rhoconnect.source_config('OtherAdapter')[:poll_interval]
    poll_interval_default.should == 201
    poll_interval_override = Rhoconnect.source_config('SimpleAdapter')[:poll_interval]
    poll_interval_override.should == 600
  end

end