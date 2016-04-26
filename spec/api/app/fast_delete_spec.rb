require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiFastDelete" do
  include_examples "ApiHelper"

  it "should delete an object from rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_delete",
      {:user_id => @u.id, :data => {'3' => @product3}}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data.delete('3')
    verify_doc_result(@s, {:md => data, :md_size =>'2'})
  end

  it "should not properly delete the object if fast_delete is called without all the attributes (because fast_delete doesn't ensure any data integrity)" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    delete_data = {'3' => {'price' => '1.99'}}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_delete",
      {:user_id => @u.id, :data => delete_data}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@s, {:md => data, :md_size=>'2'})
  end
end