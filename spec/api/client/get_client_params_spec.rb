require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiGetClientParams" do
  include_examples "ApiHelper"

  it "should list client attributes" do
    get "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}",  {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    res = JSON.parse(last_response.body)
    res.delete_if { |attrib| attrib['name'] == 'rho__id' || attrib['name'] == 'last_sync'}
    res.sort{|x,y| x['name']<=>y['name']}.should == [
      {"name"=>"device_type", "value"=>"Apple", "type"=>"string"},
      {"name"=>"device_pin", "value"=>"abcd", "type"=>"string"},
      {"name"=>"device_port", "value"=>"3333", "type"=>"string"},
      {"name"=>"device_push_type", "type"=>"string", "value"=>nil},
      {"name"=>"device_app_id", "type"=>"string", "value"=>nil},
      {"name"=>"device_app_version", "type"=>"string", "value"=>nil},
      {"name"=>"user_id", "value"=>"testuser", "type"=>"string"},
      {"name"=>"phone_id", "value"=>nil, "type"=>"string"},
      {"name"=>"app_id", "value"=>"application", "type"=>"string"}].sort{|x,y| x['name']<=>y['name']}
  end

  it "should list client attributes with old route and deprecation warning" do
    post "/api/get_client_params", {:api_token => @api_token, :client_id =>@c.id}
    res = JSON.parse(last_response.body)
    res.delete_if { |attrib| attrib['name'] == 'rho__id' || attrib['name'] == 'last_sync'}
    res.sort{|x,y| x['name']<=>y['name']}.should == [
      {"name"=>"device_type", "value"=>"Apple", "type"=>"string"},
      {"name"=>"device_pin", "value"=>"abcd", "type"=>"string"},
      {"name"=>"device_port", "value"=>"3333", "type"=>"string"},
      {"name"=>"device_push_type", "type"=>"string", "value"=>nil},
      {"name"=>"user_id", "value"=>"testuser", "type"=>"string"},
      {"name"=>"phone_id", "value"=>nil, "type"=>"string"},
      {"name"=>"app_id", "value"=>"application", "type"=>"string"}].sort{|x,y| x['name']<=>y['name']}
  end
end