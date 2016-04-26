require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "MockAdapter" do
  include_examples "SpecHelper"

  before(:each) do
    setup_test_for MockAdapter,'testuser'
  end

  it "should process MockAdapter query" do
    pending
  end

  it "should process MockAdapter create" do
    pending
  end

  it "should process MockAdapter update" do
    pending
  end

  it "should process MockAdapter delete" do
    pending
  end
end