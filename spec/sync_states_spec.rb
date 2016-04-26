require File.join(File.dirname(__FILE__),'spec_helper')

describe "Sync Server States" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    @model = Rhoconnect::Model::Base.create(@s)
    rhcud = lambda { @model.send(params[:operation].to_sym, params["#{params[:operation]}_object".to_sym]) }
    @sscud = Rhoconnect::Handler::Changes::Runner.new(['create', 'update', 'delete'], @model, @c, rhcud, {})
    rh = lambda { @model.query(params[:query]) }
    @ssq = Rhoconnect::Handler::Query::Runner.new(@model, @c, rh, {})
  end

  describe "client creates objects" do

    it "should create object and create link for client" do
      @product1['link'] = 'temp1'
      params = {'create'=>{'1'=>@product1}}
      backend_data = {'backend_id'=>@product1}
      set_doc_state(@sscud.client, :cd_size => 0)
      set_doc_state(@s, :md_size => 0)
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @sscud.params = params
      @sscud.run
      verify_source_queue_data(@s, :create => [])
      verify_doc_result(@c, {:cd_size => "1",
                             :cd => backend_data,
                             :create_links => {'1'=>{'l'=>'backend_id'}}})
      verify_doc_result(@s, {:md_size => "1",
                             :md => backend_data})
    end

    it "should create object and send link to client" do
      @product1['link'] = 'temp1'
      params = {'create'=>{'1'=>@product1}}
      backend_data = {'backend_id'=>@product1}
      set_doc_state(@sscud.client, :cd_size => 0)
      set_doc_state(@s, :md_size => 0)
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @sscud.params = params
      @sscud.run
      verify_source_queue_data(@s, :create => [])
      verify_doc_result(@c, {:cd_size => "1",
                             :cd => backend_data,
                             :create_links => {'1'=>{'l'=>'backend_id'}}})
      verify_doc_result(@s, {:md_size => "1",
                             :md => backend_data})
      res = @ssq.run
      res.should == [{'version'=>Rhoconnect::SYNC_VERSION},{"token"=>res[1]['token']},
        {"count"=>0}, {"progress_count"=>0}, {"total_count"=>1},
        {"links"=> {'1'=>{'l'=>'backend_id'}}}]

    end
  end

  describe "client deletes objects" do
    it "should delete object" do
      params = {'delete'=>{'1'=>@product1}}
      data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
      expected = {'2'=>@product2,'3'=>@product3}
      set_doc_state(@sscud.client, {:cd => data,
                                :cd_size => data.size})
      set_doc_state(@s, {:md => data,
                         :md_size => data.size})
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @sscud.params = params
      @sscud.run
      verify_source_queue_data(@s, :delete => [])
      verify_doc_result(@sscud.client, {:cd => expected,
                                     :delete_page => {},
                                     :cd_size => "2"})
      verify_doc_result(@s, {:md => expected,
                             :md_size => "2"})
      verify_result('test_delete_storage' => {'1'=>@product1})
    end
  end
end