require 'rack/test'
require 'rspec'
require 'rspec/autorun'

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','rhoconnect','server.rb')

describe "Protocol" do
  include Rack::Test::Methods
  include Rhoconnect
  include TestHelpers

  let(:test_app_name) { 'application' }

  let(:source) { 'Product' }
  let(:user_id) { 5 }
  let(:client_id)  { 1 }
  let(:product1) { {'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99'} }
  let(:product2) { {'name' => 'G2', 'brand' => 'Android', 'price' => '99.99'} }
  let(:product3) { {'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99'} }
  let(:product4) { {'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'} }
  let(:products)     { {'1' => product1,'2' => product2,'3'=> product3} }

  before(:all) do
    Rhoconnect.bootstrap(get_testapp_path) do |rhoconnect|
      rhoconnect.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end

  before(:each) do
    Store.create
    Store.flush_all
  end

  before(:each) do
    @a_fields = { :name => test_app_name }
    # @a = App.create(@a_fields)
    @a = (App.load(test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields)
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    config = Rhoconnect.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources)
    @a.users << @u.id
  end

  Rhoconnect.log_disabled = true

  before(:each) do
    $rand_id ||= 0
    $content_table ||= []
    $content ||= []
    require File.join(get_testapp_path, test_app_name)
    Rhoconnect.bootstrap(get_testapp_path) do |rhoconnect|
      rhoconnect.vendor_directory = File.join(rhoconnect.base_directory,'..','..','..','vendor')
    end
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :run, false
    Rhoconnect::Server.set :secret, "secure!"
  end

  before(:each) do
    do_post "/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    @title,@description = nil,nil
    $rand_id += 1
  end

  def app
    @app ||= Rhoconnect::Server.new
  end

  after(:each) do
    #_print_messages
    _print_markdown if @title and @description
  end

  after(:all) do
    _write_doc if $content and $content.length > 0
  end

  it "clientlogin" do
    do_post "/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    @title,@description = 'clientlogin', 'authenticate client'
  end

  it "wrong login or password clientlogin" do
    do_post "/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'wrongpass'
    @title,@description = 'clientlogin', 'login failure'
  end

  it "clientcreate" do
    get "/#{@a.name}/clientcreate"
    @title,@description = 'clientcreate', 'create client id'
  end

  it "clientcreate" do
    get "/#{@a.name}/clientcreate?device_type=iPhone&device_pin=abcd&device_port=3333"
    @title,@description = 'clientcreate-and-register', 'create client id with register params'
  end

  it "clientregister" do
    do_post "/#{@a.name}/clientregister",
      "device_type" => "iPhone", "device_pin" => "abcd",
      "device_port" => "3333", "client_id" => @c.id
    @title,@description = 'clientregister', 'register client with params'
  end

  it "clientreset" do
    get "/#{@a.name}/clientreset", :client_id => @c.id
    @title,@description = 'clientreset', 'reset client database'
  end

  ['create','update','delete'].each do |operation|
    it "client #{operation} object(s)" do
      params = {operation=>{'1'=>product1},
                :client_id => @c.id,
                :source_name => @s.name}
      do_post "/#{@a.name}", params
      @title,@description = operation, "#{operation} object(s)"
    end
  end

  it "client creates blobs" do
    body = <<eol
<pre>------------XnJLe9ZIbbGUYtzPQJ16u1
Content-Disposition: form-data; name="txtfile-rhoblob-1"; filename="upload1.txt"
Content-Type: application/octet-stream
Content-Length: 5

hello
------------XnJLe9ZIbbGUYtzPQJ16u1
Content-Disposition: form-data; name="txtfile-rhoblob-2"; filename="upload2.txt"
Content-Type: application/octet-stream
Content-Length: 5

world
------------XnJLe9ZIbbGUYtzPQJ16u1
Content-Disposition: form-data; name="cud"

{"client_id":"278c76a7ab2a4f64ba804c1aa22504f3","source_name":"SampleAdapter","version":3,"create":{"1":{"price":"199.99","brand":"Apple","name":"iPhone","txtfile-rhoblob":"upload1.txt","_id":"tempobj1"},"2":{"price":"99.99","brand":"Android","name":"G2","txtfile-rhoblob":"upload2.txt","_id":"tempobj2"}},"blob_fields":["txtfile-rhoblob"]}
------------XnJLe9ZIbbGUYtzPQJ16u1--</pre>
eol
    @title,@description = 'create', 'client creates blobs'
    $content_table << {$rand_id => "#{@title} - #{@description}"}
    data = {
      :title => @title,
      :description => @description,
      :rand_id => $rand_id,
      :req_method => 'POST',
      :req_url => '/api/application/queue_updates',
      :req_query_string => '',
      :req_content_type => "multipart/form-data; boundary=----------XnJLe9ZIbbGUYtzPQJ16u1",
      :req_content_length => 833,
      :req_cookie => "rhoconnect_session=BAh7CDoNYXBwX25hbWUiEGFwcGxpY2F0aW9uOglhdXRoIg5kZWxlZ2F0ZWQ6\nCmxvZ2luIg10ZXN0dXNlcg==\n--87659670a0625baf4cdd81bdb9bf829b4567eb35",
      :req_body => body,
      :res_status => 200,
      :res_content_type => 'text/html',
      :res_content_length => 0,
      :res_cookie => "rhoconnect_session=BAh7CDoKbG9naW4iDXRlc3R1c2VyOg1hcHBfbmFtZSIPcmhvdGVzdGFwcDoJ%0AYXV0aCIOZGVsZWdhdGVk%0A--788449811455529433e658e1c486c622f47ee0d8; path=/; expires=Mon, 04-Apr-2011 19:29:32",
      :res_body => ''
    }
    $content << data
    @title,@description = nil,nil
  end

  it "client create,update,delete objects" do
    params = {'create'=>{'1'=>product1},
              'update'=>{'2'=>product2},
              'delete'=>{'3'=>product3},
              :client_id => @c.id,
              :source_name => @s.name}
    do_post "/#{@a.name}", params
    @title,@description = 'create-update-delete', 'create,update,delete object(s)'
  end

  it "server sends link created object" do
    product4['link'] = 'test link'
    params = {'create'=>{'4'=>product4},
              :client_id => @c.id,
              :source_name => @s.name}
    do_post "/#{@a.name}", params
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,
      :version => Rhoconnect::SYNC_VERSION
    @title,@description = 'create-with-link', 'send link for created object'
  end

  it "server send source query error to client" do
    set_test_data('test_db_storage',{},"Error during query",'query error')
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    @title,@description = 'query-error', 'send query error'
  end

  it "server send source login error to client" do
    @u.login = nil
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    @title,@description = 'login-error', 'send login error'
  end

  it "server send source logoff error to client" do
    set_test_data('test_db_storage',{},"Error logging off",'logoff error')
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    @title,@description = 'logoff-error', 'send logoff error'
  end

  ['create','update','delete'].each do |operation|
    it "client #{operation} object(s) with error" do
      if operation == 'update'
        broken_object = { ERROR => { 'price' => '99.99' } }
        set_doc_state(@c, :cd => broken_object)
        set_test_data('test_db_storage',broken_object)
      end
      params = {operation=>{ERROR=>{'an_attribute'=>"error #{operation}",'name'=>'wrongname'}},
                :client_id => @c.id,
                :source_name => @s.name}
      do_post "/#{@a.name}", params
      get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
      @title,@description = "#{operation}-error", "send #{operation} error"
    end
  end

  it "server send insert objects to client" do
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>product1,'2'=>product2}
    set_test_data('test_db_storage',data)
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    @title,@description = 'insert objects', 'send insert objects'
  end

  it "server send metadata to client" do
    mock_metadata_method([SampleAdapter]) do
      cs = ClientSync.new(@s,@c,1)
      set_test_data('test_db_storage',products)
      get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    end
    @title,@description = 'metadata', 'send metadata'
  end

  it "server send delete objects to client" do
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>product1,'2'=>product2}
    set_test_data('test_db_storage',data)
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    token = Store.get_value(@c.docname(:page_token))
    Store.flush_data('test_db_storage')
    @s.read_state.refresh_time = Time.now.to_i
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
      :version => Rhoconnect::SYNC_VERSION
    @title,@description = 'delete objects', 'send delete objects'
  end

  it "server send insert,delete objects to client" do
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>product1,'2'=>product2}
    set_test_data('test_db_storage',data)
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => Rhoconnect::SYNC_VERSION
    token = Store.get_value(@c.docname(:page_token))
    set_test_data('test_db_storage',{'1'=>product1,'3'=>product3})
    @s.read_state.refresh_time = Time.now.to_i
    get "/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
      :version => Rhoconnect::SYNC_VERSION
    @title,@description = 'insert-delete objects', 'send insert and delete objects'
  end

  it "server send search results" do
    sources = [{:name=>'SampleAdapter'}]
    Store.put_data('test_db_storage',products)
    params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
      :version => Rhoconnect::SYNC_VERSION}
    get "/#{@a.name}/search",params
    @title,@description = 'search result', 'send search results'
  end

  it "should get search results with error" do
    sources = [{:name=>'SampleAdapter'}]
    msg = "Error during search"
    error = set_test_data('test_db_storage',products,msg,'search error')
    params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
      :version => Rhoconnect::SYNC_VERSION}
    get "/#{@a.name}/search",params
    @title,@description = 'search error', 'send search error'
  end

  it "should get multiple source search results" do
    Store.put_data('test_db_storage',products)
    sources = [{:name=>'SimpleAdapter'},{:name=>'SampleAdapter'}]
    params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
      :version => Rhoconnect::SYNC_VERSION}
    get "/#{@a.name}/search",params
    @title,@description = 'multi source search', 'send multiple sources in search results'
  end

  it "should ack multiple sources search results" do
    set_test_data('test_db_storage',products)
    sources = [{'name'=>'SimpleAdapter'},{'name'=>'SampleAdapter'}]
    ClientSync.search_all(@c,{:sources => sources,:search => {'search'=>'bar'}})
    @c.source_name = 'SimpleAdapter'
    token = Store.get_value(@c.docname(:search_token))
    sources[0]['token'] = token
    Store.get_data(@c.docname(:search)).should == {'obj'=>{'foo'=>'bar'}}
    @c.source_name = 'SampleAdapter'
    token = Store.get_value(@c.docname(:search_token))
    sources[1]['token'] = token
    params = {:client_id => @c.id,:sources => sources,
      :version => Rhoconnect::SYNC_VERSION}
    get "/#{@a.name}/search",params
    @title,@description = 'multi source search ack', 'acknowledge search result on multiple sources'
  end

  private
  def _print_markdown
    $content_table << {$rand_id => "#{@title} - #{@description}"}
    data = {
      :title => @title,
      :description => @description,
      :rand_id => $rand_id,
      :req_method => last_request.env['REQUEST_METHOD'],
      :req_url => last_request.env['PATH_INFO'],
      :req_query_string => last_request.env['QUERY_STRING'].empty? ? '' : "?#{last_request.env['QUERY_STRING']}",
      :req_content_type => _get_header_text(last_request.env['CONTENT_TYPE']),
      :req_content_length => _get_header_text(last_request.env['CONTENT_LENGTH']),
      :req_cookie => _get_header_text(last_request.env['HTTP_COOKIE']),
      :req_body => last_request.body.read,
      :res_status => last_response.status.to_s,
      :res_content_type => _get_header_text(last_response.headers['Content-Type']),
      :res_content_length => _get_header_text(last_response.headers['Content-Length']),
      :res_cookie => _get_header_text(last_response.headers['Set-Cookie'].split("\n")[0]),
      :res_body => last_response.body
    }
    last_request.body.rewind
    $content << data
  end

  def _write_doc
    File.open(File.join('doc','protocol.html'),'w') do |file|
      header = ERB.new(File.read(File.join(File.dirname(__FILE__),'header.html'))).result(binding)
      file.write(header)
      page = ERB.new(File.read(File.join(File.dirname(__FILE__),'base.html')))
      $content.each do |data|
        file.write(page.result(binding))
      end
      footer = ERB.new(File.read(File.join(File.dirname(__FILE__),'footer.html'))).result(binding)
      file.write(footer)
    end
  end

  def _get_header_text(header)
    header ? header : '&nbsp;'
  end
end
