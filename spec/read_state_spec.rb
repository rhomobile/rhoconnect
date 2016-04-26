require File.join(File.dirname(__FILE__),'spec_helper')

describe "ReadState" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  it "should create refresh with correct id" do
    @r.id.should == "#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}"
  end

  it "should create refresh with default fields" do
    @r.refresh_time.should <= Time.now.to_i
  end

  it "should load refresh with params" do
    @r1 = ReadState.load(:app_id => @a_fields[:name],
      :user_id => @u_fields[:login],:source_name => @s_fields[:name])
    @r1.refresh_time.should <= Time.now.to_i
  end

  it "should delete read_state from db" do
    ReadState.delete(@a_fields[:name])
    Store.keys("read_state*").should == []
  end

  it "should delete read_state from source" do
    time = Time.now.to_i
    @s.read_state.refresh_time = time
    @s.load_read_state.refresh_time.should == time

    @s.delete_user_read_state
    @s.load_read_state.should == nil
  end
end