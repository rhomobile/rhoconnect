require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiStats" do
  include_examples "ApiHelper"

  def app
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  before(:each) do
    Rhoconnect::Server.set :stats, true
    Rhoconnect.stats = true
  end

  after(:each) do
    Rhoconnect::Server.set :stats, false
    Rhoconnect.stats = false
  end

  it "should retrieve metric names" do
    Store.set_value('stat:foo', '1')
    Store.set_value('stat:bar', '2')
    get "/rc/#{Rhoconnect::API_VERSION}/system/stats", {
      :api_token => @api_token,
      :names => '*'
    }
    last_response.should be_ok
    JSON.parse(last_response.body).sort.should == ['bar', 'foo']
  end

  it "should retrieve range metric" do
    Store.zadd('stat:foo', 2, "1:2")
    Store.zadd('stat:foo', 3, "1:3")
    get "/rc/#{Rhoconnect::API_VERSION}/system/stats", {
      :metric => 'foo',
      :start => 0,
      :finish => -1
    }, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    JSON.parse(last_response.body).should == ["1:2", "1:3"]
  end

  it "should retrieve string metric" do
    Store.put_value('stat:foo', 'bar')
    get "/rc/#{Rhoconnect::API_VERSION}/system/stats", {
      :metric => 'foo'
    }, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.body.should == 'bar'
  end

  it "should retrieve string metric with old route and print deprecation warning" do
    Store.put_value('stat:foo', 'bar')
    post "/api/stats", {
      :metric => 'foo'
    }, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    last_response.body.should == 'bar'
  end

  it "should raise error on unknown metric" do
    get "/rc/#{Rhoconnect::API_VERSION}/system/stats", {
      :metric => 'foo'
    }, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.status.should == 404
    last_response.body.should == 'Unknown metric'
  end

  it "should raise error if stats not enabled" do
    Rhoconnect::Server.set :stats, false
    Rhoconnect.stats = false
    get "/rc/#{Rhoconnect::API_VERSION}/system/stats", {
      :metric => 'foo'
    }, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.status.should == 500
    last_response.body.should == 'Stats not enabled'
  end
end