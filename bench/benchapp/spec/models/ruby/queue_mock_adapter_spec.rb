require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "QueueMockAdapter" do
  include_examples "SpecHelper"

  before(:each) do
    setup_test_for QueueMockAdapter,'testuser'
  end

  it "should process QueueMockAdapter query" do
    pending
  end

  it "should process QueueMockAdapter create" do
    pending
  end

  it "should process QueueMockAdapter update" do
    pending
  end

  it "should process QueueMockAdapter delete" do
    pending
  end
end