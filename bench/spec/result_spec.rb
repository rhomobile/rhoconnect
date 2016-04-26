$:.unshift File.join(File.dirname(__FILE__))
require 'bench_spec_helper'
require 'rest_client'

describe "ResultSpec" do
  include Utils
  include_examples "BenchSpecHelper"

  before(:each) do
    @s1 = [{"foo" => {"bar" => "cake"}}]
    @s2 = [{"foo" => {"bar" => "cake1"}},{"hello" => "world"}]
    @result = Result.new("marker",:get,"some/url",0,1)
    client = double("RestClient")
    client.stub(:headers).and_return({'header1'=>'headervalue1'})
    client.stub(:cookies).and_return({'session1'=>'sessval1'})
    client.stub(:code).and_return(200)
    client.stub(:to_s).and_return(@s1.to_json)
    @result.last_response = client
  end

  describe "test @last_response wrapper" do

    it "should return 'code'" do
      @result.code.should == 200
    end

    it "should return 'body'" do
      JSON.parse(@result.body).should == @s1
    end

    it "should return 'cookies'" do
      @result.cookies.should == {'session1'=>'sessval1'}
    end

    it "shhould return 'headers'" do
      @result.headers.should == {'header1'=>'headervalue1'}
    end

  end

  it "should compare two array/hash structures" do
    compare(:expected,@s1,:actual,@s2).should == [{:expected=>"cake",
      :path=>[0, "foo", "bar"], :actual=>"cake1"},
      {:expected=>nil, :path=>[1], :actual=>{"hello"=>"world"}}]
  end

  it "should verify body" do
    @result.should_receive(:bench_log).exactly(8).times
    @result.verify_body(@s2.to_json)
    @result.verification_error.should == 1
  end

  it "should verify code" do
    @result.should_receive(:bench_log).exactly(4).times
    @result.verify_code(500)
    @result.verification_error.should == 1
  end
end