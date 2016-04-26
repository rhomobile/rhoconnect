require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "SourceJob" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true
  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    @s.query_queue = 'query'
    @s.cud_queue = 'cud'
  end

  it "should perform process_query" do
    set_state('test_db_storage' => @data)
    SourceJob.perform('query',@s.id,@s.app_id,@s.user_id,nil)
    verify_doc_result(@s, {:md => @data,
                           :md_size => @data.size.to_s})
  end

  it "should perform process_cud" do
    expected = {'backend_id'=>@product1}
    @product1['link'] = 'abc'
    @s.push_queue(:create, @c.id, [[@s.name, [['1', @product1]]]])
    SourceJob.perform('cud',@s.id,@s.app_id,@s.user_id,nil)
    verify_source_queue_data(@s, :create => [])
    verify_doc_result(@s, {:md => expected,
                           :md_size => expected.size.to_s})
    verify_doc_result(@c, {:cd => expected,
                           :cd_size => expected.size.to_s})
  end
end