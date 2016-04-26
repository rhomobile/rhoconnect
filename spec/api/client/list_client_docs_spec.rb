require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiListClientDocs" do
  include_examples "ApiHelper"

  it "should list client documents" do
    source_id = "SimpleAdapter"
    Client.define_valid_doctypes(['mycustomdoc'])
    get "/rc/#{Rhoconnect::API_VERSION}/clients/#{@c.id}/sources/#{source_id}/docnames", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    JSON.parse(last_response.body).should == {
      "cd"=>"client:application:testuser:#{@c.id}:#{source_id}:cd",
      "cd_size"=>"client:application:testuser:#{@c.id}:#{source_id}:cd_size",
      "page"=>"client:application:testuser:#{@c.id}:#{source_id}:page",
      "delete_page"=>"client:application:testuser:#{@c.id}:#{source_id}:delete_page",
      "create_links"=>"client:application:testuser:#{@c.id}:#{source_id}:create_links",
      "create_links_page"=>"client:application:testuser:#{@c.id}:#{source_id}:create_links_page",
      "metadata_page"=>"client:application:testuser:#{@c.id}:#{source_id}:metadata_page",
      "total_count_page"=>"client:application:testuser:#{@c.id}:#{source_id}:total_count_page",
      "page_token"=>"client:application:testuser:#{@c.id}:#{source_id}:page_token",
      "schema_sha1"=>"client:application:testuser:#{@c.id}:#{source_id}:schema_sha1",
      "schema_page"=>"client:application:testuser:#{@c.id}:#{source_id}:schema_page",
      "metadata_sha1"=>"client:application:testuser:#{@c.id}:#{source_id}:metadata_sha1",
      "search"=>"client:application:testuser:#{@c.id}:#{source_id}:search",
      "search_token"=>"client:application:testuser:#{@c.id}:#{source_id}:search_token",
      "search_page"=>"client:application:testuser:#{@c.id}:#{source_id}:search_page",
      "search_errors"=>"client:application:testuser:#{@c.id}:#{source_id}:search_errors",
      "create_errors"=>"client:application:testuser:#{@c.id}:#{source_id}:create_errors",
      "create_errors_page"=>"client:application:testuser:#{@c.id}:#{source_id}:create_errors_page",
      "update_errors"=>"client:application:testuser:#{@c.id}:#{source_id}:update_errors",
      "update_errors_page"=>"client:application:testuser:#{@c.id}:#{source_id}:update_errors_page",
      "update_rollback"=>"client:application:testuser:#{@c.id}:#{source_id}:update_rollback",
      "update_rollback_page"=>"client:application:testuser:#{@c.id}:#{source_id}:update_rollback_page",
      "delete_errors"=>"client:application:testuser:#{@c.id}:#{source_id}:delete_errors",
      "delete_errors_page"=>"client:application:testuser:#{@c.id}:#{source_id}:delete_errors_page",
      "mycustomdoc"=>"client:application:testuser:#{@c.id}:#{source_id}:mycustomdoc"}

    Client.valid_doctypes.delete('mycustomdoc'.to_sym)
  end
end

