require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Rhoconnect::Model::DynamicAdapterModel" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  it "should return login when backend service defined" do
    stub_request(:post, "http://test.com/rhoconnect/authenticate").to_return(:body => "lucas")
    Rhoconnect.appserver = 'http://test.com'
    Rhoconnect::Model::DynamicAdapterModel.authenticate('lucas', '').should == 'lucas'
  end

  it "should query dynamic adapter service" do
    data = {'1' => @product1}
    stub_request(:post, "http://test.com/rhoconnect/query").with(:headers => {'Content-Type' => 'application/json'}).to_return(:status => 200, :body => data.to_json)
    da = Rhoconnect::Model::DynamicAdapterModel.new(@s2, nil, 'http://test.com')
    da.query.should == data
  end

  it "should create new object using dynamic adapter" do
    stub_request(:post, "http://test.com/rhoconnect/create").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5}.to_json)
    da = Rhoconnect::Model::DynamicAdapterModel.new(@s2, nil, 'http://test.com')
    da.create(@product1).should == {:id => 5}.to_json
  end

  it "should update object using dynamic adapter" do
    data = {'id' => 2}
    stub_request(:post, "http://test.com/rhoconnect/update").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5}.to_json)
    da = Rhoconnect::Model::DynamicAdapterModel.new(@s2, nil, 'http://test.com')
    da.update(data).should == {:id => 5}.to_json
  end

  it "should delete object using dynamic adapter" do
    data = {'id' => 2}
    stub_request(:post, "http://test.com/rhoconnect/delete").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5}.to_json)
    da = Rhoconnect::Model::DynamicAdapterModel.new(@s2, nil, 'http://test.com')
    da.delete(data).should == {:id => 5}.to_json
  end
end