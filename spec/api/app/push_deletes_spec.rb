require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiPushDeletes" do
  include_examples "ApiHelper"

  it "should delete object from :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_doc_state(@s, {:md => data, :md_size => '3'})
    data.delete('2')
    post "/app/#{Rhoconnect::API_VERSION}/#{@s_fields[:name]}/push_deletes",
      {:user_id => @u.id, :objects => ['2']}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(@s, {:md => data, :md_size=>'2'})
  end
end