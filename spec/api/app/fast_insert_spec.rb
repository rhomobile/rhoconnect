require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiFastInsert" do
  include_examples "ApiHelper"

  it "should append new objects to rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '2'})
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_insert",
      {:user_id => @u.id, :data => {'3' => @product3}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data.merge!({'3' => @product3})
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should incorrectly append data to existing object (because fast_insert doesn't ensure any data integrity)" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    incorrect_insert = {'3' => {'price' => '1.99', 'new_field' => 'value'}}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_insert",
      {:user_id => @u.id, :data => incorrect_insert}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data['3'].merge!(incorrect_insert['3'])
    verify_doc_result(@s, :md_size=>'4')
  end
end