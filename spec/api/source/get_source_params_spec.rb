require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiGetSourceParams" do
  include_examples "ApiHelper"

  it "should list source attributes" do
    source_id = "SampleAdapter"
    get "/rc/#{Rhoconnect::API_VERSION}/sources/#{source_id}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    result = JSON.parse(last_response.body).sort {|x,y| y["name"] <=> x["name"] }
    expected = [
      {"name"=>"rho__id", "value"=>"SampleAdapter", "type"=>"string"},
      {"name"=>"source_id", "value"=>nil, "type"=>"integer"},
      {"name"=>"name", "value"=>"SampleAdapter", "type"=>"string"},
      {"name"=>"url", "value"=>"http://example.com", "type"=>"string"},
      {"name"=>"login", "value"=>"testuser", "type"=>"string"},
      {"name"=>"password", "value"=>"testpass", "type"=>"string"},
      {"name"=>"priority", "value"=>1, "type"=>"integer"},
      {"name"=>"callback_url", "value"=>nil, "type"=>"string"},
      {"name"=>"poll_interval", "value"=>300, "type"=>"integer"},
      {"name"=>"retry_limit", "type"=>"integer", "value"=>0},
      {"name"=>"simulate_time", "value"=>0, "type"=>"integer"},
      {"name"=>"partition_type", "value"=>"user", "type"=>"string"},
      {"name"=>"push_notify", "value"=>"false", "type"=>"string"},
      {"name"=>"sync_type", "value"=>"incremental", "type"=>"string"},
      {"name"=>"belongs_to", "type"=>"string", "value"=>nil},
      {"name"=>"has_many", "type"=>"string", "value"=>"FixedSchemaAdapter,brand"},
      {"name"=>"id", "value"=>"SampleAdapter", "type"=>"string"},
      {"name"=>"queue", "value"=>nil, "type"=>"string"},
      {"name"=>"query_queue", "value"=>nil, "type"=>"string"},
      {"name"=>"pass_through", "value"=>nil, "type"=>"string"},
      {"name"=>"cud_queue", "value"=>nil, "type"=>"string"}].sort {|x,y| y["name"] <=> x["name"] }
    result.each_with_index do |item,i|
      expect = expected[i]
      item['name'].should == expect['name']
      item['value'].should == expect['value']
      item['type'].should == expect['type']
    end
  end
end

