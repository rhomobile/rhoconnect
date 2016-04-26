$:.unshift File.join(File.dirname(__FILE__))
require 'bench_spec_helper'

describe "UtilsSpec" do
  include Utils
  include Logging

  include_examples "BenchSpecHelper"

  it "should compare two identical hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value2'}}
    compare(:expected,h1,:actual,h2).should == []
  end

  it "should compare two different hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value3'}}
    compare(:expected,h1,:actual,h2).should ==
      [{:actual=>"value3", :path=>["key1", "key2"], :expected=>"value2"}]
  end

  it "should compare_and_log two identical hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value2'}}
    Bench::Utils.should_not_receive(:bench_log)
    compare_and_log(h1,h2,'the caller').should == 0
  end

  it "should compare_and_log two different hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value3'}}
    compare_and_log(h1,h2,'the caller').should == 1
  end
end