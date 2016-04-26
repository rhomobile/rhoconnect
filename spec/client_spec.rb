require File.join(File.dirname(__FILE__),'spec_helper')

STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

describe "Client" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
  end

  it "should create client with fields" do
    @c.id.length.should == 32
    @c.device_type.should == @c_fields[:device_type]
  end

  it "should update_fields for a client" do
    @c.update_fields({:device_type => 'android',:device_port => 100})
    @c.device_type.should == 'android'
    @c.device_port.should == '100'
  end

  it "should create client with user_id" do
    Store.get_value('client:count').should == "1"
    @c.id.length.should == 32
    @c.user_id.should == @c_fields[:user_id]
    @u.clients.members.should == [@c.id]
  end

  it "should raise exception if source_name is nil" do
    @c.source_name = nil
    lambda {
      @c.doc_suffix('foo')
    }.should raise_error(InvalidSourceNameError, 'Invalid Source Name For Client')
  end

  it "should delete client and all associated documents" do
    @c.put_data(:cd, @data)
    docname = @c.docname(:cd)
    store_index = @c.store_index(:cd)
    @c.delete
    Store.get_store(store_index).exists?(docname).should == false
  end

  it "should switch client user and remove existing documents" do
    prevdocname = @c.docname(:cd)
    prev_store_index = @c.store_index(:cd)
    @c.put_data(:cd, @data)
    verify_doc_result(@c, :cd => @data)
    User.create({:login => 'user2'})
    @c.switch_user('user2')
    verify_doc_result(@c, :cd => {})
    Store.get_store(prev_store_index).get_data(prevdocname).should == {}
    @u.clients.members.should == []
    @c.user_id.should == 'user2'
    User.load('user2').clients.members.should == [@c.id]
  end

  it "should create cd as masterdoc clone" do
    @s.put_data(:md_copy, @data)
    @c.put_data(:cd, {'foo' => {'bar' => 'abc'}})
    @c.update_clientdoc([@s_fields[:name]])
    verify_doc_result(@c, :cd => @data)
    verify_doc_result(@s, :md_copy => @data)
  end

  it "should update client schema_sha1" do
    @s.put_data(:md_copy, @data)
    @s.put_value(:schema_sha1, 'foobar')
    @c.put_data(:cd, {'foo' => {'bar' => 'abc'}})
    @c.update_clientdoc([@s_fields[:name]])
    verify_doc_result(@c, :cd => @data)
    verify_doc_result(@s, :md_copy => @data)
    verify_doc_result(@c, :schema_sha1 => 'foobar')
  end

  describe "Client Stats" do

    before(:each) do
      Rhoconnect::Stats::Record.reset('clients')
    end

    after(:each) do
      Rhoconnect::Stats::Record.reset('clients')
    end

    after(:all) do
      Store.flush_data('stat:clients*')
    end

    it "should increment clients stats on create" do
      Time.stub(:now).and_return(10)
      Rhoconnect.stats = true
      @c_fields.delete(:id)
      Client.create(@c_fields,{:source_name => @s_fields[:name]})
      Rhoconnect::Stats::Record.range('clients',0,-1).should == ["2:10"]
      Store.get_value('client:count').should == "2"
      Rhoconnect.stats = false
    end

    it "should decrement clients stats on delete" do
      Time.stub(:now).and_return(10)
      Rhoconnect.stats = true
      @c_fields.delete(:id)
      c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
      Rhoconnect::Stats::Record.range('clients',0,-1).should == ["2:10"]
      c.delete
      Rhoconnect::Stats::Record.range('clients',0,-1).should == ["1:10"]
      Store.get_value('client:count').should == "1"
      Rhoconnect.stats = false
    end
  end
end