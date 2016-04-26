require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiFastUpdate" do
  include_examples "ApiHelper"

  it "should update an attribute and add new one for an object in rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})

    orig_obj_attrs = {'3' => {'price' => @product3['price']}}
    new_obj_attrs = {'3' => {'price' => '0.99', 'new_attr' => 'new_value'}}

    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_update",
      {:user_id => @u.id, :delete_data => orig_obj_attrs, :data => new_obj_attrs}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data['3'].merge!(new_obj_attrs['3'])
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should update an attribute and add new one for an object in rhoconnect's :md using old route with deprecation warning" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})

    orig_obj_attrs = {'3' => {'price' => @product3['price']}}
    new_obj_attrs = {'3' => {'price' => '0.99', 'new_attr' => 'new_value'}}

    post "/api/source/fast_update",
      {:user_id => @u.id, :source_id => @s_fields[:name], :delete_data => orig_obj_attrs, :data => new_obj_attrs}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    last_response.headers["Warning"].index('deprecated').should_not == nil
    data['3'].merge!(new_obj_attrs['3'])
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should update one attr, add one attr, and remove one attr for an object in rhoconnect's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})

    orig_obj_attrs = {'3' => {'name' => @product3['name'], 'price' => @product3['price']}}
    new_obj_attrs = {'3' => {'price' => '0.99', 'new_attr' => 'new_value'}}

    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_update",
      {:user_id => @u.id, :delete_data => orig_obj_attrs, :data => new_obj_attrs}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data['3'].delete('name')
    data['3'].merge!(new_obj_attrs['3'])
    verify_doc_result(@s, {:md => data, :md_size=>'3'})
  end

  it "should remove all attributes , and properly adjust md_size" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})

    orig_obj_attrs = {'3' => @product3}
    new_obj_attrs = {}

    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/fast_update",
      {:user_id => @u.id, :delete_data => orig_obj_attrs, :data => new_obj_attrs}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    data.delete('3')
    verify_doc_result(@s, {:md => data, :md_size=>'2'})
  end
end