require File.join(File.dirname(__FILE__),'spec_helper')

describe "Document" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    @valid_docs = [:foo1, :foo, :key, :key1, :key2]
    Client.define_valid_doctypes(@valid_docs)
    @s = Source.load(@s_fields[:name],@s_params)
  end

  after(:each) do
    @valid_docs.each do |doctype|
      Client.valid_doctypes.delete(doctype)
    end
  end

  it "should generate client docname" do
    @c.docname(:foo).should == "client:#{@a.id}:#{@u.id}:#{@c.id}:#{@s_fields[:name]}:foo"
  end

  it "should generate InvalidDocumentException for invalid client doctype" do
    lambda { @c.put_data(:foo_invalid,{'1'=>@product1}) }.should raise_error(InvalidDocumentException, "Invalid document type foo_invalid for Rhoconnect::Client")
    store_index = @c.store_index(:foo_invalid)
    Store.get_store(store_index).db.keys(@c.docname('*')).should == []
  end

  it "should generate source docname" do
    @s.docname(:foo).should == "source:#{@a.id}:#{@u.id}:#{@s_fields[:name]}:foo"
  end

  it "should flush_data for docname" do
    @c.put_data(:foo1,{'1'=>@product1})
    docname = @c.docname(:foo1)
    bucket_index = get_sha1('1')[0..1]
    store_index = @c.store_index(:foo1)
    Store.get_store(store_index).db.keys(@c.docname('*')).sort.should == ["#{docname}:#{bucket_index}", "#{docname}:indices"].sort
    @c.flush_all_documents
    Store.get_store(store_index).db.keys(@c.docname('*')).should == []
  end

  it "should flush_data for arrays" do
    @c.put_list(:foo1,['1', '2', '3'])
    @c.exists?(:foo1).should == true
    @c.flush_all_documents
    @c.exists?(:foo1).should == false
  end

  it "should get_data for arrays" do
    @c.put_list(:foo1,['1', '2', '3'])
    @c.get_data(:foo1, Array).should == ['1', '2', '3']
    JSON.parse(@c.get_db_doc(:foo1)).should == ['1', '2', '3']
  end

  it "should rename doc" do
    @c.put_data(:key1, @data)
    @c.rename(:key1,:key2)
    @c.exists?(:key1).should == false
    @c.get_data(:key2).should == @data
  end

  it "should operate with individual object" do
    key = '1'
    data = {'foo' => 'bar'}
    @c.put_object(:cd, key, data)
    obj = @c.get_object(:cd, key)
    obj.should == data
  end
end