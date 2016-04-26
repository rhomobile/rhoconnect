require 'rack/test'
require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

describe "Rhoconnect::RhoInternalJsBenchAdapterController" do
  include Rack::Test::Methods
  include Rhoconnect
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  def app
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  before(:each) do
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :secret, "secure!"
    Rhoconnect.use_node = true
    Rhoconnect.bootstrap(get_testapp_path)
    do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
  end

  after(:each) do
    Rhoconnect::Store.flush_all
    Rhoconnect::Node.kill_process
  end

  it "should call query method" do
    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok
    body = JSON.parse(last_response.body)
  end

  it "should call create method" do
    hsh = {'create'=>{'1'=>{'mockId'=>'1','name'=>'testname','price'=>'$199'}}}
    post '/app/v1/RhoInternalJsBenchAdapter', hsh,{Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok

    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    body[5]["insert"]["mockId"]["mockId"].should == "1"
  end

  it "should call update method" do
    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    body[4]["total_count"].should == 0

    hsh = {'create'=>{'1'=>{'mockId'=>'1','name'=>'testname','price'=>'$199'}}}
    post '/app/v1/RhoInternalJsBenchAdapter', hsh,{Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok

    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    token =  last_response.headers["X-Rhoconnect-PAGE-TOKEN"]
    count = body[4]["total_count"]
    count.should == 1

    get '/app/v1/RhoInternalJsBenchAdapter', {:token=>token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    count = body[4]["total_count"]
    count.should == 1

    hsh = {'update'=>{'mockId'=>'1','name'=>'updatename'}}
    put '/app/v1/RhoInternalJsBenchAdapter/mockId',hsh, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok

    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    puts "body is #{body}"
    token =  last_response.headers["X-Rhoconnect-PAGE-TOKEN"]
    #body[5]["insert"]["mockId"]["name"].should == "updatename"

    get '/app/v1/RhoInternalJsBenchAdapter', {:token=>token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    puts "body is #{body}"
    last_response.should be_ok
  end

  it "should call delete method" do
    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    body[4]["total_count"].should == 0

    hsh = {'create'=>{'1'=>{'mockId'=>'1','name'=>'testname','price'=>'$199'}}}
    post '/app/v1/RhoInternalJsBenchAdapter', hsh,{Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok

    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body    = JSON.parse(last_response.body)
    token =  last_response.headers["X-Rhoconnect-PAGE-TOKEN"]
    count = body[4]["total_count"]
    count.should == 1

    get '/app/v1/RhoInternalJsBenchAdapter', {:token => token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    count = body[4]["total_count"]
    count.should == 1

    delete '/app/v1/RhoInternalJsBenchAdapter/1',{}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    last_response.should be_ok

    get '/app/v1/RhoInternalJsBenchAdapter', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body    = JSON.parse(last_response.body)
    token =  last_response.headers["X-Rhoconnect-PAGE-TOKEN"]

    get '/app/v1/RhoInternalJsBenchAdapter', {:token => token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
    body = JSON.parse(last_response.body)
    body[4]["total_count"].should == 0
  end
end