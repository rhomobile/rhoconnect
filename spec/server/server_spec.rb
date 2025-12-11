require 'rack/test'

require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'rhoconnect', 'server.rb')

describe "Server" do
  include Rack::Test::Methods
  include Rhoconnect
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    Rhoconnect::Server.set :secret, "secure!"
    Rhoconnect::Server.use Rack::Static, :urls => ["/data"],
                           :root => File.expand_path(File.join(File.dirname(__FILE__), '..', 'apps', 'rhotestapp'))
  end

  def app
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  it "should show status page" do
    get '/'
    expect(last_response.status).to eq(302)
  end

  it "should login if content-type contains extra parameters" do
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", {"login" => 'rhoadmin', "password" => ''}.to_json, {'CONTENT_TYPE' => 'application/json; charset=UTF-8'}
    expect(last_response).to be_ok
  end

  it "should fail to login if wrong content-type" do
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", {"login" => 'rhoadmin', "password" => ''}.to_json, {'CONTENT_TYPE' => 'application/x-www-form-urlencoded'}
    expect(last_response).not_to be_ok
  end

  it "should login as rhoadmin user" do
    post "/rc/#{Rhoconnect::API_VERSION}/system/login", "login" => 'rhoadmin', "password" => ''
    expect(last_response).to be_ok
  end

  it "should respond with 404 if controller name is not specified" do
    get "/app/#{Rhoconnect::API_VERSION}/"
    expect(last_response.status).to eq(404)
  end

  it "should have default session secret" do
    expect(Rhoconnect::Server.secret).to eq("secure!")
  end

  it "should update session secret to default" do
    Rhoconnect::Server.set :secret, "<changeme>"
    expect(Rhoconnect::Server.secret).to eq("<changeme>")
    allow(Rhoconnect::Server).to receive(:log).with(any_args())
    check_default_secret!("<changeme>")
    Rhoconnect::Server.set :secret, "secure!"
  end

  describe "helpers" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    it "should return nil if params[:source_name] is missing" do
      get "/application"
      expect(last_response.status).to eq(500)
    end
  end

  describe "auth routes" do
    it "should login user with correct username,password" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
      expect(last_response).to be_ok
    end

    it "should login user with correct username,password old route and deprecation warning" do
      do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
      expect(last_response).to be_ok
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
    end

    it "should login user with correct username,password if backend service defined" do
      stub_request(:post, "http://test.com/rhoconnect/authenticate").to_return(:body => "lucas")
      Rhoconnect.appserver = 'http://test.com'
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'lucas', "password" => 'testpass'
      expect(last_response).to be_ok
    end

    it "should return 401 and LoginException messsage from authenticate" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'wrongpass'
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq('login exception')
    end

    it "should return 500 and Exception messsage from authenticate" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'server error'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('server error')
    end

    it "should return 401 and no messsage from authenticate if no exception raised" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'wrongpassnomsg'
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq("Unable to authenticate '#{@u.login}'")
    end

    it "should create unknown user through delegated authentication" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'newuser', "password" => 'testpass'
      expect(User.is_exist?('newuser')).to be true
      expect(@a.users.members.sort).to eq(['newuser', 'testuser'])
    end

    it "should create a different username through delegated authentication" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'newuser', "password" => 'diffuser'
      expect(User.is_exist?('different')).to be true
      expect(@a.users.members.sort).to eq(['different', 'testuser'])
    end

    context "rps authenticate" do
      it "should authenticate user with rps route" do
        # RPS login should always come after normal login
        do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
        authorize 'rpsuser', 'secret'
        get "/rc/#{Rhoconnect::API_VERSION}/app/rps_login", {}
        expect(last_response.status).to eq(204)
      end
    end

    context "rps app authenticate" do
      it "should authenticate rhoconnect app with correct push server credentials" do
        # Test app push server settings are
        # :push_server: http://user:pwd@localhost:8675
        authorize 'user', 'pwd'
        get "/rc/#{Rhoconnect::API_VERSION}/system/rps_login", {}
        expect(last_response.status).to eq(204)
      end
      it "should not authenticate rhoconnect app with invalid rhoconnect push server credentials" do
        authorize 'someappname', ''
        get "/rc/#{Rhoconnect::API_VERSION}/system/rps_login", {}
        expect(last_response.status).to eq(401)
      end
      it "should not authenticate rhoconnect app with invalid basic Authorization header in request" do
        # Basic Authorization header is missing
        get "/rc/#{Rhoconnect::API_VERSION}/system/rps_login", {}
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe "controller custom routes" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    it "should register custom_route in DefaultServer and process it" do
      Rhoconnect::Server.api4 '', "/my_custom_route", :get do
        "Hello World!"
      end

      get "/my_custom_route", {}
      expect(last_response.body).to eq("Hello World!")
    end

    it "should register custom_route in SimpleAdapter controller and process it" do
      SimpleAdapterController.get '/my_custom_route', {:client_required => true, :source_required => true} do
        "Hello World!"
      end
      get "/app/#{Rhoconnect::API_VERSION}/SimpleAdapter/my_custom_route", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response.body).to eq("Hello World!")
    end

    it "should register custom_route in SimpleAdapter controller, require client condition and return error if client is missing" do
      SimpleAdapterController.get '/my_custom_route_with_client', {:client_required => true, :source_required => true} do
        "Hello World!"
      end
      get "/app/#{Rhoconnect::API_VERSION}/SimpleAdapter/my_custom_route_with_client", {}
      expect(last_response.body).to eq("Unknown client")
      expect(last_response.status).to eq(500)
    end
  end

  describe "client management routes" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    it "should respond to clientcreate" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/clients", 'device_type' => 'Android'
      expect(last_response).to be_ok
      expect(last_response.content_type).to match /application\/json/
      id = JSON.parse(last_response.body)['client']['client_id']
      expect(id.length).to eq(32)
      expect(JSON.parse(last_response.body)).to eq({"client" => {"client_id" => id}})
      c = Client.load(id, {:source_name => '*'})
      expect(c.user_id).to eq('testuser')
      expect(c.device_type).to eq('Android')
    end

    it "should respond to clientcreate with old route and deprecation warning" do
      get "/application/clientcreate?device_type=Android"
      expect(last_response).to be_ok
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
      expect(last_response.content_type).to match /application\/json/
      id = JSON.parse(last_response.body)['client']['client_id']
      expect(id.length).to eq(32)
      expect(JSON.parse(last_response.body)).to eq({"client" => {"client_id" => id}})
      c = Client.load(id, {:source_name => '*'})
      expect(c.user_id).to eq('testuser')
      expect(c.device_type).to eq('Android')
    end

    it "should respond to clientregister" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/register",
              "device_type" => "iPhone", "device_pin" => 'abcd'
      expect(last_response).to be_ok
      expect(@c.device_type).to eq('Apple')
      expect(@c.device_pin).to eq('abcd')
      expect(@c.id.length).to eq(32)
    end

    it "should respond to clientregister without clientcreate" do
      Store.flush_data("client*")
      client_id = @c.id.clone
      @c = nil
      do_post "/rc/#{Rhoconnect::API_VERSION}/clients/#{client_id}/register",
              "device_type" => "iPhone", "device_pin" => 'abcd'
      expect(last_response).to be_ok
      @c = Client.load(client_id, {:source_name => '*'})
      expect(@c.device_type).to eq('iPhone')
      expect(@c.device_pin).to eq('abcd')
      expect(@c.id.length).to eq(32)
    end

    it "should respond to clientreset" do
      set_doc_state(@c, :cd => @data)
      do_post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/reset", {}
      verify_doc_result(@c, :cd => {})
    end

    it "should respond to clientreset with old route and deprecation warning" do
      set_doc_state(@c, :cd => @data)
      get "/application/clientreset", 'client_id' => @c.id
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
      verify_doc_result(@c, :cd => {})
    end

    it "should respond to clientreset with individual adapters" do
      @c.source_name = 'SimpleAdapter'
      set_doc_state(@c, :cd => @data)
      @c.source_name = 'SampleAdapter'
      set_doc_state(@c, :cd => @data)
      sources = [{'name' => 'SimpleAdapter'}]
      do_post "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/reset", 'sources' => sources
      expect(last_response).to be_ok
      @c.source_name = 'SampleAdapter'
      verify_doc_result(@c, :cd => @data)
      @c.source_name = 'SimpleAdapter'
      verify_doc_result(@c, :cd => {})
    end

    it "should switch client user if client user_id doesn't match session user" do
      set_test_data('test_db_storage', @data)
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body).last['insert']).to eq(@data)
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'user2', "password" => 'testpass'
      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body).last['insert']).to eq(data)
    end

    it "should return error on routes if client doesn't exist" do
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => "BrokenClient"}
      expect(last_response.body).to eq("Unknown client")
      expect(last_response.status).to eq(500)
    end
  end

  describe "source routes" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    it "should post records for create" do
      @product1['_id'] = '1'
      params = {'create' => {'1' => @product1}}
      do_post "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq('')
      verify_result("test_create_storage" => {'1' => @product1})
    end

    it "should post records for update" do
      params = {'update' => @product1}
      do_put "/app/#{Rhoconnect::API_VERSION}/#{@s.name}/1", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq('')
      verify_result("test_update_storage" => {'1' => @product1})
    end

    it "should post records for update using the old route and have the deprecation warning" do
      params = {'update' => {'1' => @product1}, :client_id => @c.id, :source_name => @s.name,
                :version => Rhoconnect::SYNC_VERSION}
      do_post "/application", params
      expect(last_response).to be_ok
      expect(last_response.body).to eq('')
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
      verify_result("test_update_storage" => {'1' => @product1})
    end

    it "should post records for delete" do
      set_doc_state(@c, :cd => @data)
      delete "/app/#{Rhoconnect::API_VERSION}/#{@s.name}/1", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq('')
      verify_result("test_delete_storage" => {'1' => @product1})
    end

    it "should post records for delete using the old route with deprecation warning" do
      params = {'delete' => {'1' => @product1}, :client_id => @c.id, :source_name => @s.name,
                :version => Rhoconnect::SYNC_VERSION}
      do_post "/api/application/queue_updates", params
      expect(last_response).to be_ok
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
      expect(last_response.body).to eq('')
      verify_result("test_delete_storage" => {'1' => @product1})
    end

    it "should handle client posting broken json" do
      broken_json = "{\"foo\":\"bar\"\"}"
      do_post "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", broken_json, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq("Server error while processing client data")
    end

    it "should not login if login is empty" do
      post "/rc/#{Rhoconnect::API_VERSION}/app/login", ''
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq("Unable to authenticate ''")
    end

    xit "should resend page if page exists and no token provided" do
      expected = {'1' => @product1}
      set_test_data('test_db_storage', {'1' => @product1, '2' => @product2, '4' => @product4})
      params = {'name' => 'iPhone'}
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:query => params}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.content_type).to match /application\/json/
      token = @c.get_value(:page_token)
      expect(last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER]).to eq(token)
      last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER].should == 1.to_s
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 1}, {"progress_count" => 0}, {"total_count" => 1}, {'insert' => expected}])
      # this should re-send the page
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:query => params}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.content_type).to match /application\/json/
      token1 = @c.get_value(:page_token)
      expect(token1).to eq(token)
      expect(last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER]).to eq(token)
      last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER].should == 1.to_s
      JSON.parse(last_response.body).should == [{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token1},
                                                {"count" => 1}, {"progress_count" => 0}, {"total_count" => 1}, {'insert' => expected}]
      # this should ack_token
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:token => token, :query => params}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.content_type).to match /application\/json/
      last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER].should == ""
      last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER].should == 0.to_s
      JSON.parse(last_response.body).should == [{'version' => Rhoconnect::SYNC_VERSION}, {"token" => ""},
                                                {"count" => 0}, {"progress_count" => 0}, {"total_count" => 1}, {}]
      @c.get_data(:page).should == {}
      @c.get_value(:page_token).should be_nil
    end

    it "should get inserts json" do
      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.content_type).to match /application\/json/
      token = @c.get_value(:page_token)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 2}, {'insert' => data}])
    end

    it "should get inserts json with the old route and show deprecation warning" do
      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)
      get "/application", :client_id => @c.id, :source_name => @s.name, :version => Rhoconnect::SYNC_VERSION
      expect(last_response).to be_ok
      expect(last_response.headers["Warning"].index('deprecated')).not_to be_nil
      expect(last_response.content_type).to match /application\/json/
      token = @c.get_value(:page_token)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 2}, {'insert' => data}])
    end

    it "should get inserts json and confirm token" do
      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      token = @c.get_value(:page_token)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 2}, {'insert' => data}])
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:token => token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => ''},
                                                {"count" => 0}, {"progress_count" => 0}, {"total_count" => 2}, {}])
    end

    # check custom partitions
    it "should return data for user with custom partition name" do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => 'cus_user1', "password" => 'testpass'
      @c_fields = {
          :device_type => 'Apple',
          :device_pin => 'abcd',
          :device_port => '3333',
          :user_id => 'cus_user1',
          :app_id => @a.id
      }
      @c = Client.create(@c_fields, {:source_name => @s_fields[:name]})
      @s = Source.load('SampleAdapter', {:user_id => 'cus_user1', :app_id => APP_NAME})

      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      token = @c.get_value(:page_token)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 2}, {'insert' => data}])
      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:token => token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => ''},
                                                {"count" => 0}, {"progress_count" => 0}, {"total_count" => 2}, {}])
      expect(@s.docname(:md)).to eq("source:#{@s.app.id}:custom_partition:SampleAdapter:md")
      verify_doc_result(@s, :md => data)
    end

    it "should create source for dynamic adapter if source_name is unknown" do
      get "/app/#{Rhoconnect::API_VERSION}/Broken", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response.status).to eq(200)
    end

    it "should create source for dynamic adapter if source_name is unknown using the old route" do
      get "/api/application/query", {:source_name => @s_fields[:name], :client_id => @c.id}
      expect(last_response.status).to eq(200)
    end

    it "should get deletes json" do
      @s = Source.load(@s_fields[:name], @s_params)
      data = {'1' => @product1, '2' => @product2}
      set_test_data('test_db_storage', data)

      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      token = @c.get_value(:page_token)
      expect(last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER]).to eq(token)
      expect(last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER]).to eq(2.to_s)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 2}, {'insert' => data}])

      Store.flush_data('test_db_storage')
      @s.read_state.refresh_time = Time.now.to_i

      get "/app/#{Rhoconnect::API_VERSION}/#{@s.name}", {:token => token}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      token = @c.get_value(:page_token)
      expect(last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER]).to eq(token)
      expect(last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER]).to eq(2.to_s)
      expect(JSON.parse(last_response.body)).to eq([{'version' => Rhoconnect::SYNC_VERSION}, {"token" => token},
                                                {"count" => 2}, {"progress_count" => 0}, {"total_count" => 0}, {'delete' => data}])
    end

    it "should get search results using the old route with deprecation warning" do
      sources = [{:name => 'SampleAdapter'}]
      Store.put_data('test_db_storage', @data)
      params = {:client_id => @c.id, :sources => sources, :search => {'name' => 'iPhone'},
                :version => Rhoconnect::SYNC_VERSION}
      get "/api/application/search", params
      expect(last_response.headers['Warning'].index('deprecated')).not_to be_nil
      expect(last_response.content_type).to match /application\/json/
      token = @c.get_value(:search_token)
      expect(last_response.headers[Rhoconnect::PAGE_TOKEN_HEADER]).to eq(token)
      expect(last_response.headers[Rhoconnect::PAGE_OBJECT_COUNT_HEADER]).to eq(1.to_s)
      expect(JSON.parse(last_response.body)).to eq([[{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token},
                                                 {'source' => sources[0][:name]}, {'count' => 1}, {'insert' => {'1' => @product1}}]])
    end

    it "should get search results" do
      sources = [{:name => 'SampleAdapter'}]
      Store.put_data('test_db_storage', @data)
      params = {:sources => sources, :search => {'name' => 'iPhone'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response.content_type).to match /application\/json/
      token = @c.get_value(:search_token)
      expect(JSON.parse(last_response.body)).to eq([[{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token},
                                                 {'source' => sources[0][:name]}, {'count' => 1}, {'insert' => {'1' => @product1}}]])
    end

    it "should get search results with error" do
      sources = [{:name => 'SampleAdapter'}]
      msg = "Error during search"
      error = set_test_data('test_db_storage', @data, msg, 'search error')
      params = {:sources => sources, :search => {'name' => 'iPhone'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq([[{'version' => Rhoconnect::SYNC_VERSION}, {'source' => sources[0][:name]},
                                                 {'search-error' => {'search-error' => {'message' => msg}}}]])
      verify_doc_result(@c, :search => {})
    end

    it "should get multiple source search results" do
      Store.put_data('test_db_storage', @data)
      sources = [{:name => 'SimpleAdapter'}, {:name => 'SampleAdapter'}]
      params = {:sources => sources, :search => {'search' => 'bar'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      @c.source_name = 'SimpleAdapter'
      token1 = @c.get_value(:search_token)
      @c.source_name = 'SampleAdapter'
      token = @c.get_value(:search_token)
      expect(JSON.parse(last_response.body)).to eq([
          [{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token1}, {"source" => "SimpleAdapter"},
           {"count" => 1}, {"insert" => {'obj' => {'foo' => 'bar'}}}],
          [{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token}, {"source" => "SampleAdapter"},
           {"count" => 1}, {"insert" => {'1' => @product1}}]])
      verify_doc_result(@c, {:search => {'1' => @product1},
                             :search_errors => {}})
    end

    it "should handle search for pass through" do
      sources = [{'name' => 'SampleAdapter'}]
      set_state('test_db_storage' => @data)
      @s.pass_through = 'true'
      params = {:sources => sources, :search => {'name' => 'iPhone'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      token = @c.get_value(:search_token)
      expect(JSON.parse(last_response.body)).to eq([[{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token},
                                                 {'source' => sources[0]['name']}, {'count' => 1}, {'insert' => {'1' => @product1}}]])
      verify_doc_result(@c, {:search => {},
                             :search_errors => {}})
    end

    it "should handle multiple source search with one source returning nothing" do
      set_test_data('test_db_storage', @data)
      sources = [{'name' => 'SimpleAdapter'}, {'name' => 'SampleAdapter'}]
      params = {:sources => sources, :search => {'name' => 'iPhone'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      @c.source_name = 'SimpleAdapter'
      token1 = @c.get_value(:search_token)
      expect(token1).to be_nil
      @c.source_name = 'SampleAdapter'
      token = @c.get_value(:search_token)
      expect(JSON.parse(last_response.body)).to eq([[], [{'version' => Rhoconnect::SYNC_VERSION}, {'token' => token},
                                                     {"source" => "SampleAdapter"}, {"count" => 1}, {"insert" => {'1' => @product1}}]])
    end

    it "should handle search and ack of search results" do
      set_test_data('test_db_storage', @data)
      sources = [{'name' => 'SimpleAdapter'}, {'name' => 'SampleAdapter'}]
      params = {:sources => sources, :search => {'search' => 'bar'}}
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      @c.source_name = 'SimpleAdapter'
      token = @c.get_value(:search_token)
      expect(token).not_to be_nil
      sources[0]['token'] = token
      expect(@c.get_data(:search)).to eq({'obj' => {'foo' => 'bar'}})
      @c.source_name = 'SampleAdapter'
      token1 = @c.get_value(:search_token)
      expect(token1).not_to be_nil
      sources[1]['token'] = token1
      expect(@c.get_data(:search)).to eq('1' => @product1)
      # do ack on multiple sources
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/search", params, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      @c.source_name = 'SimpleAdapter'
      token = @c.get_value(:search_token)
      expect(token).to be_nil
      expect(@c.get_data(:search)).to eq({})
      @c.source_name = 'SampleAdapter'
      token1 = @c.get_value(:search_token)
      expect(token1).to be_nil
      expect(@c.get_data(:search)).to eq({})
    end
  end

  describe "bulk data routes" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end

    after(:each) do
      delete_data_directory
    end

    it "should make initial bulk data request (which creates Resque job) and receive wait (and no deprecation warning)" do
      set_state('test_db_storage' => @data)
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq({:result => :wait}.to_json)
      warning_header = last_response.headers['Warning']
      expect(warning_header).to be_nil or expect(warning_header.index('deprecated')).to be_nil
      expect(Resque.peek(:bulk_data)).to eq({"args" =>
                                             [{"data_name" => File.join(@a_fields[:name], @u_fields[:login], @u_fields[:login])}],
                                         "class" => "Rhoconnect::BulkDataJob"})
    end

    it "should make old-way initial bulk data request and receive wait along with deprecation warning" do
      set_state('test_db_storage' => @data)
      get "/application/bulk_data", :partition => :user, :client_id => @c.id
      expect(last_response).to be_ok
      expect(last_response.body).to eq({:result => :wait}.to_json)
      expect(last_response.headers['Warning'].index('deprecated')).not_to be_nil
    end

    it "should make old-way initial bulk data request and receive wait along with deprecation warning (Sources sent as String)" do
      set_state('test_db_storage' => @data)
      get "/application/bulk_data?sources=FixedSchemaAdapter,SampleAdapter", :partition => :user, :client_id => @c.id
      expect(last_response).to be_ok
      expect(last_response.body).to eq({:result => :wait}.to_json)
      expect(last_response.headers['Warning'].index('deprecated')).not_to be_nil
    end

    it "should receive url when bulk data is available" do
      set_state('test_db_storage' => @data)
      @a.sources.delete('JsSample')
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, @u.id))
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      data = BulkData.load(bulk_data_docname(@a.id, @u.id))
      expect(last_response.body).to eq({:result => :url,
                                        :url => data.url}.to_json)
      validate_db(data, {@s.name => @data, 'FixedSchemaAdapter' => @data})
    end

    it "should download bulk data file" do
      set_state('test_db_storage' => @data)
      @a.sources.delete('JsSample')
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, @u.id))
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq({'result' => 'url',
                                                'url' => BulkData.load(bulk_data_docname(@a.id, @u.id)).url})
      get JSON.parse(last_response.body)["url"]
      expect(last_response).to be_ok
      File.open('test.data', 'wb') {|f| f.puts last_response.body}
      validate_db_file('test.data', [@s.name, 'FixedSchemaAdapter'], {@s.name => @data, 'FixedSchemaAdapter' => @data})
      File.delete('test.data')
      verify_doc_result(@c, :cd => @data)
      verify_doc_result(@s, {:md => @data,
                             :md_copy => @data})
    end

    it "should receive nop when no sources are available for partition" do
      set_state('test_db_storage' => @data)
      Source.load('SimpleAdapter', @s_params).partition = :user
      @a.sources.delete('OtherAdapter')
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :app}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq({:result => :nop}.to_json)
    end

    it "should create bulk data job app partition with partition sources" do
      @s.partition = :app
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :app}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      expect(last_response.body).to eq({:result => :wait}.to_json)
      warning_header = last_response.headers['Warning']
      expect(warning_header).to be_nil or expect(warning_header.index('deprecated')).to be_nil
      expect(Resque.peek(:bulk_data)).to eq({"args" =>
                                             [{"data_name" => File.join(@a_fields[:name], @a_fields[:name])}],
                                         "class" => "Rhoconnect::BulkDataJob"})
    end

    it "should return empty bulk data url if there are errors in query" do
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, @u.id))
      operation = 'query'
      @s.lock(:errors) do
        @s.put_data(:errors, {"#{operation}-error" => {'message' => "Some exception message"}}, true)
      end
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq('result' => 'url', 'url' => '')
    end

    it "should return bulk data url for completed bulk data app partition" do
      set_state('test_db_storage' => @data)
      @s.partition = :app
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :app}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, "*"))
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :app}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq({'result' => 'url',
                                                'url' => BulkData.load(bulk_data_docname(@a.id, "*")).url})
      @c.source_name = @s.name
      verify_doc_result(@c, :cd => @data)
      verify_doc_result(@s, {:md => @data,
                             :md_copy => @data})
    end

    it "should return bulk data url for completed bulk data with bulk_sync_only source" do
      set_state('test_db_storage' => @data)
      @a.sources.delete('JsSample')
      @s.sync_type = :bulk_sync_only
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, @u.id))
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq({'result' => 'url',
                                                'url' => BulkData.load(bulk_data_docname(@a.id, @u.id)).url})
      @c.source_name = @s.name
      verify_doc_result(@c, :cd => {})
      verify_doc_result(@s, {:md => @data,
                             :md_copy => {}})
    end

    it "should create bulk data job if no file exists" do
      set_state('test_db_storage' => @data)
      @a.sources.delete('JsSample')
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      do_bulk_data_job("data_name" => bulk_data_docname(@a.id, @u.id))
      data = BulkData.load(bulk_data_docname(@a.id, @u.id))
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq({'result' => 'url', 'url' => data.url})
      File.delete(data.dbfile)
      post "/rc/#{Rhoconnect::API_VERSION}/app/bulk_data", {:partition => :user}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(JSON.parse(last_response.body)).to eq({'result' => 'wait'})
      expect(Resque.peek(:bulk_data)).to eq({"args" =>
                                             [{"data_name" => bulk_data_docname(@a.id, @u.id)}], "class" => "Rhoconnect::BulkDataJob"})
    end
  end

  describe "blob sync" do
    before(:each) do
      do_post "/rc/#{Rhoconnect::API_VERSION}/app/login", "login" => @u.login, "password" => 'testpass'
    end
    it "should upload blob in multipart post" do
      file1, file2 = 'upload1.txt', 'upload2.txt'
      @product1['txtfile-rhoblob'] = file1
      @product1['_id'] = 'tempobj1'
      @product2['txtfile-rhoblob'] = file2
      @product2['_id'] = 'tempobj2'
      cud = {'create' => {'1' => @product1, '2' => @product2},
             :blob_fields => ['txtfile-rhoblob']}.to_json
      post "/app/#{Rhoconnect::API_VERSION}/#{@s.name}",
           {:cud => cud, 'txtfile-rhoblob-1' =>
               Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), '..', 'testdata', file1), "application/octet-stream"),
            'txtfile-rhoblob-2' =>
                Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), '..', 'testdata', file2), "application/octet-stream")}, {Rhoconnect::CLIENT_ID_HEADER => @c.id}
      expect(last_response).to be_ok
      data = Store.get_data('test_create_storage')
      expect(data.size).to eq(2)
      data.each do |id, obj|
        expect(File.exist?(obj['txtfile-rhoblob'])).to be true
      end
    end
  end
end
