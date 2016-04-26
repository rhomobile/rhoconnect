require 'rack/test'
require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

describe "Rhoconnect::Controller::JsBase" do
  include Rack::Test::Methods
  include Rhoconnect

  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  def app
    @app = Rack::URLMap.new Rhoconnect.url_map
  end

  def remove_application_controller
    Object.send(:remove_const, :ApplicationController) rescue nil
  end

  after(:all) do
    Rhoconnect.use_node = false
  end

  def bootstrap_rhoconnect(jsapp = false)
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :secret, "secure!"
    Rhoconnect.use_node = true
    if jsapp
      Rhoconnect.bootstrap(get_jstestapp_path)
    else
      Rhoconnect.bootstrap(get_testapp_path)
    end
    # reload ruby controllers
    Dir[File.join(Rhoconnect.app_directory,'controllers','ruby','*.rb')].each do |controller_file|
      load controller_file
    end
    # reload ruby models
    Dir[File.join(Rhoconnect.app_directory,'models','ruby','*.rb')].each do |model_file|
      load model_file
    end
  end

  describe "ApplicationController" do
    after(:all) do
      Rhoconnect.remove_from_url_map(ApplicationController)
      remove_application_controller
    end

    it "should call Store api in ApplicationController" do
      Rhoconnect.remove_from_url_map(ApplicationController)
      remove_application_controller
      bootstrap_rhoconnect(true)
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'storeapitest', "password" => 'testpass'
      Store.get_value('loginkey').should == 'storeapitest'
    end

    it "should use user defined :node_channel_timeout value for test environment" do
      Rhoconnect.remove_from_url_map(ApplicationController)
      remove_application_controller
      bootstrap_rhoconnect(true)
      Rhoconnect::NodeChannel.timeout.should == 60
    end
  end

  describe "Named Controller" do
    before(:each) do
      bootstrap_rhoconnect
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    it "should get / of js controller with route overridden" do
      get '/app/v1/JsSample', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.should be_ok
      body = JSON.parse(last_response.body)
      body[2]['count'].should == 1
      body.last['insert'].should == {'1' => {'name' => 'iPhone'}}
    end

    it "should get /custom_route of js controller" do
      get '/app/v1/JsSample/custom_route', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.body.should == 'testuser'
    end

    it "should get /source from custom route" do
      get '/app/v1/JsSample/custom_route2', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.body.should == 'JsSample'
    end

    it "should get stash_result from js model" do
      pending "stash_result not supported yet"
      get '/app/v1/JsSample/custom_route3',{}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      res = JSON.parse(last_response.body)
      res[2]["count"].should == 1
    end

    it "should register sync route" do
      get '/app/v1/Sample2', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      res = JSON.parse(last_response.body)
      res[2]["count"].should == 1
    end

    it "should post to js controller" do
      hsh = {'1'=>{'name'=>'testname','price'=>'$199'}}
      post '/app/v1/JsSample',hsh, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.should be_ok
    end

    it "should put to js controller" do
      put '/app/v1/JsSample/2', {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.body.should == ''
    end

    it "should delete to js controller" do
      @c1 = Client.create({:user_id => @u.id,:app_id => @a.id},{:source_name => 'JsSample'})
      set_doc_state(@c1, :cd => @data)
      delete '/app/v1/JsSample/2', {}, {Rhoconnect::CLIENT_ID_HEADER => @c1.id}
      last_response.should be_ok
    end

    it "should call route that overrides default option" do
      get '/app/v1/JsSample/no_client_route', {}
      last_response.should be_ok
      last_response.body.should == 'no client required!'
    end

    it "should upload blob in multipart post" do
      file1,file2 = 'upload1.txt'
      @product1['txtfile-rhoblob'] = file1
      @product1['_id'] = 'tempobj1'
      cud = {'create'=>{'1'=>{'name'=>'hello'}},
        :blob_fields => ['txtfile-rhoblob']}.to_json
      post "/app/#{Rhoconnect::API_VERSION}/JsSample",
          {:cud => cud,'txtfile-rhoblob-1' =>
            Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__),'..','testdata',file1), "application/octet-stream")},
            {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      last_response.should be_ok
      get "/app/#{Rhoconnect::API_VERSION}/JsSample", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      json = JSON.parse(last_response.body)
      json[5]['links'].should == { "1" => { "l" => "blob_created" } }
      json[5]['delete'].should == { "blob_created" => { "name" => "hello", "txtfile-rhoblob" => "blob_created" } }
    end

    it "should push_objects to js controller" do
      s = Source.load('JsSample', @s_params)
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      post "/app/#{Rhoconnect::API_VERSION}/JsSample/push_objects",
        {:user_id => @u.id, :objects => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
      last_response.should be_ok
      verify_doc_result(s, {:md => data, :md_size=>'3'})
    end

    it "should push_deletes to js controller" do
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      s = Source.load('JsSample',@s_params)
      set_doc_state(s, {:md => data, :md_size => '3'})
      data.delete('2')
      post "/app/#{Rhoconnect::API_VERSION}/JsSample/push_deletes",
        {:user_id => @u.id, :objects => ['2']}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
      last_response.should be_ok
      verify_doc_result(s, {:md => data, :md_size=>'2'})
    end
  end
end