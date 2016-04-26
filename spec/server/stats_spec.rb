require 'rhoconnect'
require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

include Rhoconnect

describe "Middleware" do

  before(:each) do
    @now = 10.0
    Store.flush_all
    app = double('app')
    app.stub(:call)
    Rhoconnect.stats = true
    Rhoconnect::Server.enable :stats
    @middleware_new_routes = Rhoconnect::Middleware::Stats.new(app)
    Store.stub(:lock).and_yield
  end

  after(:each) do
    Rhoconnect.stats = false
    Rhoconnect::Server.disable :stats
  end

  it "should compute http average" do
    @incr = 0
    Time.stub(:now).and_return do
      if @incr > 0
        @now += 0.3
        @incr -= 1
      end
      @now
    end
    env = {
      'rack.request.query_hash' => {
        'source_name' => 'SampleAdapter'
      },
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/api/application/query'
    }
    10.times { @incr = 3; @middleware_new_routes.call(env) }
    metric = 'http:GET:/api/application/query:SampleAdapter'
    Rhoconnect::Stats::Record.key(metric).should == "stat:#{metric}"

    # The conversion algorithm (float to string) currently checks two precisions.
    # it tries 16 digits and if that's not enough it then uses 17.
    Rhoconnect::Stats::Record.range(metric, 0, -1).should == [
      "2.0,0.6000000000000014:12",
      "2.0,0.6000000000000014:14",
      "2.0,0.6000000000000014:16",
      "2.0,0.6000000000000014:18"
    ]
  end
end