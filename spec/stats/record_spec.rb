require 'rhoconnect'
require File.join(File.dirname(__FILE__),'..','spec_helper')

STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

include Rhoconnect

describe "Record" do

  before(:each) do
    @now = 9
    Store.create
    Store.flush_all
    Store.stub(:lock).and_yield
  end

  it "should add metric to the record and trim record size" do
    Time.stub(:now).and_return { @now }
    10.times { @now += 1; Rhoconnect::Stats::Record.add('foo') }
    Store.zrange('stat:foo', 0, -1).should == ["2:12", "2:14", "2:16", "2:18"]
  end

  it "should add single record" do
    Time.stub(:now).and_return { @now += 1; @now }
    Rhoconnect::Stats::Record.add('foo')
    Store.zrange('stat:foo', 0, -1).should == ["1:10"]
  end

  it "should return type of metric" do
    Rhoconnect::Stats::Record.add('foo')
    Rhoconnect::Stats::Record.rtype('foo').should == 'zset'
  end

  it "should set string metric" do
    Rhoconnect::Stats::Record.set_value('foo', 'bar')
    Store.get_value('stat:foo').should == 'bar'
  end

  it "should get string metric" do
    Store.put_value('stat:foo', 'bar')
    Rhoconnect::Stats::Record.get_value('foo').should == 'bar'
  end

  it "should get keys" do
    Rhoconnect::Stats::Record.add('foo')
    Rhoconnect::Stats::Record.add('bar')
    Rhoconnect::Stats::Record.keys.sort.should == ['bar','foo']
  end

  it "should add absolute metric value" do
    Time.stub(:now).and_return { @now }
    time = 0
    4.times do
      @now += 1
      Rhoconnect::Stats::Record.save_average('foo',time)
      time += 1
    end
    Store.zrange('stat:foo', 0, -1).should == ["2.0,1.0:10", "2.0,5.0:12"]
  end

  it "should update metric" do
    Rhoconnect.stats = true
    @incr = 0
    Time.stub(:now).and_return do
      if @incr > 0
        @now += 1
        @incr -= 1
      end
      @now
    end
    4.times do
      @now += 1
      Rhoconnect::Stats::Record.update('foo') do
        @incr = 2
      end
    end
    Store.zrange('stat:foo', 0, -1).should == ["1,1.0:14", "1,1.0:18", "1,1.0:20"]
    Rhoconnect.stats = false
  end

  it "should get range of metric values" do
    Time.stub(:now).and_return { @now }
    10.times { @now += 1; Rhoconnect::Stats::Record.add('foo') }
    Rhoconnect::Stats::Record.range('foo', 0, 1).should == ["2:12", "2:14"]
  end

  it "should reset metric" do
    Time.stub(:now).and_return { @now }
    10.times { @now += 1; Rhoconnect::Stats::Record.add('foo') }
    Store.zrange('stat:foo', 0, -1).should == ["2:12", "2:14", "2:16", "2:18"]
    Rhoconnect::Stats::Record.reset('foo')
    Store.zrange('stat:foo', 0, -1).should == []
  end

  it "should reset all metrics" do
    Rhoconnect::Stats::Record.add('foo')
    Rhoconnect::Stats::Record.add('bar')
    Rhoconnect::Stats::Record.reset_all
    Store.keys('stat:*').should == []
  end
end