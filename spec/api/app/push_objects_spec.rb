require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiPushObjects" do
  include_examples "ApiHelper"

  it "should push new objects to rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/push_objects",
      {:user_id => @u.id, :objects => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should push new objects to rhoconnect's :md with old api/source route and deprecation warning" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    post "/api/source/push_objects",
      {:user_id => @u.id, :source_id => @s_fields[:name], :objects => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should push new objects to rhoconnect's :md with oldest api route and deprecation warning" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    post "/api/push_objects",
      {:user_id => @u.id, :source_id => @s_fields[:name], :objects => data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should push updates to existing objects to rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    update = {'price' => '0.99', 'new_field' => 'value'}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})
    update.each do |key,value|
      data['2'][key] = value
    end
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/push_objects",
      {:user_id => @u.id, :objects => {'2'=>update}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end
end