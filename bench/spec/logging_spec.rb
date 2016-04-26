$:.unshift File.join(File.dirname(__FILE__))
require 'bench_spec_helper'

describe "Logging" do

  before(:each) do
    @mc = MockClient.new(1,2,123)   
  end

  it "should get prefix" do
    @mc.log_prefix.should == "[T:001|I:002]"
  end
    
end
  