require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkData" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    @s1 = Source.load(@s1_fields[:name], @s_params)
  end

  after(:each) do
    delete_data_directory
  end

  it "should return true if bulk data is completed" do
    dbfile = create_datafile(File.join(@a.name,@u.id.to_s),@u.id.to_s)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :completed,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.dbfile = dbfile
    data.completed?.should == true
  end

  it "should return false if bulk data isn't completed" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.completed?.should == false
  end

  it "should expire_bulk_data from a source adapter" do

    @model = Rhoconnect::Model::Base.create(@s)
    @engine = Rhoconnect::Handler::Query::Engine.new(@model, lambda { @model.query }, {})
    time = Time.now.to_i + 10000
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]],
      :refresh_time => time)
    @model.expire_bulk_data
    data = BulkData.load(bulk_data_docname(@a.id,@u.id))
    data.refresh_time.should <= Time.now.to_i
  end

  it "should enqueue sqlite db type" do
    BulkData.enqueue
    Resque.peek(:bulk_data).should == {"args"=>[{}],
      "class"=>"Rhoconnect::BulkDataJob"}
  end

  it "should generate correct bulk data name for user partition" do
    BulkData.get_name(:user,@c.user_id).should == File.join(@a_fields[:name],@u_fields[:login],@u_fields[:login])
  end

  it "should generate correct bulk data name for app partition" do
    BulkData.get_name(:app,@c.user_id).should ==
      File.join(@a_fields[:name],@a_fields[:name])
  end

  it "should have ordered sources list by priority" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => @a.partition_sources(:user, @u.id))

    data.sources[0, -1].should == ["SampleAdapter", "JsSample", "FixedSchemaAdapter"]
    p1 = Source.load("SampleAdapter", {:app_id => data.app_id, :user_id => data.user_id}).priority
    p2 = Source.load("JsSample", {:app_id => data.app_id, :user_id => data.user_id}).priority
    p1.should < p2
  end

  it "should process_sources for bulk data" do
    current = Time.now.to_i
    @s.read_state.refresh_time = current
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name], @s1_fields[:name]])
    data.process_sources
    @s.read_state.refresh_time.should > current + @s_fields[:poll_interval].to_i
    @s1.read_state.refresh_time.should > current + @s1_fields[:poll_interval].to_i
  end

  it "should process specific sources for bulk data" do
    current = Time.now.to_i
    @s.read_state.refresh_time = current
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s1_fields[:name]])
    data.process_sources
    @s.read_state.refresh_time.should <= current
    @s1.read_state.refresh_time.should > current + @s1_fields[:poll_interval].to_i
  end

  it "should delete source masterdoc copy on delete" do
    set_state('test_db_storage' => @data)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.process_sources
    verify_doc_result(@s, :md_copy => @data)
    data.delete
    verify_doc_result(@s, {:md_copy => {},
                           :md => @data})
  end

  it "should escape bulk data url" do
    name = 'a b'
    data = BulkData.create(:name => bulk_data_docname(@a.id,name),
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => name,
        :sources => [@s_fields[:name]])
    do_bulk_data_job("data_name" => bulk_data_docname(@a.id,name))
    data = BulkData.load(bulk_data_docname(@a.id,name))
    data.url.should match /a%20b/
    data.delete
  end

  def create_datafile(dir,name)
    dir = File.join(Rhoconnect.data_directory,dir)
    FileUtils.mkdir_p(dir)
    fname = File.join(dir,name+'.data')
    File.open(fname,'wb') {|f| f.puts ''}
    fname
  end
end