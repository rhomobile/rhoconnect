require File.join(File.dirname(__FILE__),'spec_helper')

describe "Source" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
  end

  it "should create and load source with @s_fields and @s_params" do
    @s.name.should == @s_fields[:name]
    @s.url.should == @s_fields[:url]
    @s.login.should == @s_fields[:login]
    @s.app.name.should == @a_fields[:name]
    @s.priority.should == 1
    @s.callback_url.should be_nil
    @s.queue.should be_nil
    @s.query_queue.should be_nil
    @s.cud_queue.should be_nil
    @s.app_id.should == @s_params[:app_id]
    @s.user_id.should == @s_params[:user_id]
    @s.sync_type.should == :incremental
    @s.partition_type.should == :user
    @s.poll_interval.should == 300

    @s1 = Source.load(@s.id,@s_params)
    @s1.name.should == @s_fields[:name]
    @s1.url.should == @s_fields[:url]
    @s1.login.should == @s_fields[:login]
    @s1.app.name.should == @a_fields[:name]
    @s1.priority.should == 1
    @s1.callback_url.should be_nil
    @s1.poll_interval.should == 300
    @s1.app_id.should == @s_params[:app_id]
    @s1.user_id.should == @s_params[:user_id]
  end

  it "should create source with user" do
    @s.user.login.should == @u_fields[:login]
  end

  it "should create source with app and document" do
    @s.app.name.should == @a_fields[:name]
    @s.docname(:md).should == "source:#{@s.app.id}:#{@u.id}:#{@s_fields[:name]}:md"
  end

  it 'should return values that set by setter method' do
    @s.login = "shurab"
    @s.login.should == "shurab"
    @s.poll_interval = 350
    @s.poll_interval.should == 350
    @s.poll_interval = nil
    @s.poll_interval.should == nil
    @s.url = nil
    @s.url.should be_nil
  end

  it "should delete source" do
    @s.delete
    Source.is_exist?(@s_fields[:name]).should == false
    @s = Source.create(@s_fields,@s_params)
  end

  it "should delete master and all documents associated with source" do
    key = @s.docname('*')
    Source.define_valid_doctypes([:md_source])
    set_doc_state(@s, {:md_source => @data})
    @s.delete
    i = 0
    while i < Store.num_stores do
      Store.get_store(i).keys(key).should == []
      i += 1
    end
    Source.valid_doctypes.delete(:md_source)
    @s = Source.create(@s_fields,@s_params)
  end

  it "should create source with default partition user" do
    @s1 = Source.load(@s_fields[:name],{:app_id => @a.id,:user_id => '*'})
    @s1.partition.should == :user
  end

  it "should create correct docname based on partition scheme" do
    @s.partition = :app
    @s.docname(:md).should == "source:#{@s.app.id}:__shared__:#{@s_fields[:name]}:md"
  end

  it "should create source with default read/write queue" do
    @s.delete
    @s_fields[:queue] = :default
    @s_fields[:query_queue] = :query
    @s_fields[:cud_queue] = :cud
    @s = Source.create(@s_fields,@s_params)
    s = Source.load(@s_fields[:name],@s_params)
    s.queue.should == :default
    s.query_queue.should == :query
    s.cud_queue.should == :cud
  end

  it "should add associations based on belongs_to field for a source" do
    @s2 = Source.create({:name => 'SimpleAdapter'}, @s_params)
    @s2.belongs_to = [{'product_id' => 'SampleAdapter'}].to_json
    sf = Source.load(@s1.name,{:app_id => @a.id,:user_id => '*'})
    Source.update_associations([@s.name,@s1.name, @s2.name])
    s = Source.load(@s.name,{:app_id => @a.id,:user_id => '*'})
    s.has_many.should == "#{@s1.name},brand,#{@s2.name},product_id"
  end

  it "should log warning about incorrect belongs_to format for a source" do
    @s2 = Source.create({:name => 'SimpleAdapter'}, @s_params)
    @s2.belongs_to = {'product_id' => 'SampleAdapter'}.to_json
    Source.should_receive(:log).once.with(
      "WARNING: Incorrect belongs_to format for SimpleAdapter, belongs_to should be an array."
    )
    Source.update_associations([@s.name,@s1.name, @s2.name])
  end

  # check custom partitions
  it "should return custom partition for users if defined in the model" do
    u1_fields = {:login => 'cus_user1'}
    u1 = User.create(u1_fields)
    u2_fields = {:login => 'cus_user2'}
    u2 = User.create(u2_fields)
    u3_fields = {:login => 'other_user'}
    u3 = User.create(u3_fields)

    s = Source.load('SampleAdapter', {:user_id => u1.login, :app_id => APP_NAME})
    s.user_by_partition.should == 'custom_partition'
    s.docname(:md).should == "source:#{s.app.id}:custom_partition:SampleAdapter:md"
    s = Source.load('FixedSchemaAdapter', {:user_id => u1.login, :app_id => APP_NAME})
    s.user_by_partition.should == 'cus_user1'
    s = Source.load('SampleAdapter', {:user_id => u2.login, :app_id => APP_NAME})
    s.user_by_partition.should == 'custom_partition'
    s = Source.load('SampleAdapter', {:user_id => u3.login, :app_id => APP_NAME})
    s.user_by_partition.should == 'other_user'
  end

  it "should delete data from custom partition" do
    u1_fields = {:login => 'cus_user1'}
    u1 = User.create(u1_fields)
    data = {'1' => {'Name' => 'Value'}}

    s = Source.load('SampleAdapter', {:user_id => u1.login, :app_id => APP_NAME})
    s.user_by_partition.should == 'custom_partition'
    Source.define_valid_doctypes([:md_source])
    set_doc_state(s, {:md_source => data})
    Store.get_data("source:#{s.app.id}:custom_partition:SampleAdapter:md_source").should == data
    Store.get_data("source:#{s.app.id}:cus_user1:SampleAdapter:md_source").should == {}
    Store.put_data("source:#{s.app.id}:cus_user1:SampleAdapter:md_source", data)

    s.delete
    Store.get_data("source:#{s.app.id}:custom_partition:SampleAdapter:md_source").should == {}
    Store.get_data("source:#{s.app.id}:cus_user1:SampleAdapter:md_source").should == data
    Source.valid_doctypes.delete(:md_source)
  end
end