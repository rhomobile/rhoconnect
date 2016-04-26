# When shared examples are called as
#   include_examples "SharedRhoconnectHelper", :rhoconnect_data => false
# then :rhoconnect_data group (@product1, ..., @data) skipped.
# To enable this group call examples as
#   include_examples "SharedRhoconnectHelper", :rhoconnect_data => true
shared_examples "SharedRhoconnectHelper" do |params|
  include TestHelpers
  let(:test_app_name) { 'application' }

  before(:each) do
    Store.create
    Store.flush_all
    Rhoconnect.use_node = false
    Rhoconnect::Server.set :environment, :test

    Rhoconnect.bootstrap(get_testapp_path) do |rhoconnect|
      rhoconnect.vendor_directory = File.join(File.dirname(__FILE__), '..', '..', 'vendor')
    end

    # "DBObjectsHelper"
    @a_fields = { :name => test_app_name }
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
      :priority => '1'
    }
    @s1_fields = {
      :name => 'FixedSchemaAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :priority => '5'
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.create(@s_fields,@s_params)
    @s1 = Source.create(@s1_fields,@s_params)
    @s2 = Source.create({:name=> 'Product2'},@s_params)
    @s3 = Source.create({:name=> 'SimpleAdapter',:partition_type=> 'app'},@s_params)
    @s1.belongs_to = [{'brand' => 'SampleAdapter'}].to_json
    config = Rhoconnect.source_config('FixedSchemaAdapter')
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    @a.sources << @s3.id
    Source.update_associations(@a.sources)
    @a.users << @u.id
    @api_token = get_api_token

    # "RhoconnectDataHelper"
    if params && params[:rhoconnect_data]
      @source = 'Product'
      @user_id = 5
      @client_id = 1

      @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
      @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
      @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
      @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

      @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
    end
  end
end

shared_examples "BenchSpecHelper" do
  before(:each) do
    Store.create
    Store.flush_all

    @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
    @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
    @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
    @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end

shared_examples "ApiHelper" do
  include Rack::Test::Methods
  include Rhoconnect
  include TestHelpers

  let(:test_app_name) { 'application' }

  def app
    Rhoconnect::Server.set :stats, false
    Rhoconnect.stats = false
    @app ||= Rack::URLMap.new Rhoconnect.url_map
  end

  before(:each) do
    Rhoconnect.connection_pool_timeout = 30
    Rhoconnect.connection_pool_size = 5
    Store.create
    Store.flush_all

    Rhoconnect.use_node = false
    Rhoconnect.bootstrap(get_testapp_path) do |rhoconnect|
      rhoconnect.vendor_directory = File.join(rhoconnect.base_directory,'..','..','..','vendor')
    end
    Rhoconnect::Server.set :environment, :test
    Rhoconnect::Server.set :run, false
    Rhoconnect::Server.set :secret, "secure!"

    @a_fields = { :name => test_app_name }
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
      :priority => '1'
    }
    @s1_fields = {
      :name => 'FixedSchemaAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :priority => '5'
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.create(@s_fields,@s_params)
    @s1 = Source.create(@s1_fields,@s_params)
    @s2 = Source.create({:name=> 'Product2'},@s_params)
    @s1.belongs_to = [{'brand' => 'SampleAdapter'}].to_json
    config = Rhoconnect.source_config('FixedSchemaAdapter')
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources)
    @a.users << @u.id
    @api_token = get_api_token

    @source = 'Product'
    @user_id = 5
    @client_id = 1

    @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
    @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
    @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
    @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end

