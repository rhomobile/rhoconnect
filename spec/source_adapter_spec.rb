require File.join(File.dirname(__FILE__),'spec_helper')

describe "loading Model" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  it "should load Model instance from user name" do
    username = 'testuser'
    model_instance = SimpleAdapter.load(username)
    model_instance.class.name.should == 'SimpleAdapter'
    model_instance.source.name.should == 'SimpleAdapter'
  end
end

describe "Model" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  before(:each) do
    @s = Source.load('SimpleAdapter',@s_params)
    @sa = Rhoconnect::Model::Base.create(@s)
  end

  def setup_adapter(name)
    fields = {
      :name => name,
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    Source.create(fields,@s_params)
  end

  it "should create model with source" do
    @sa.class.name.should == @s.name
  end

  it "should create all existing pre-defined models" do
    Rhoconnect.predefined_sources.keys.sort.should == ['RhoInternalBenchmarkAdapter'].sort
    Rhoconnect.predefined_sources.each do |adapter_name, filename|
      pas = Source.load(adapter_name, @s_params)
      pas.should_not == nil
      pa = Rhoconnect::Model::Base.create(pas)
      pa.class.name.should == "Rhoconnect::#{adapter_name}"
    end
  end

  it "should create DynamicAdapterModel" do
    @sa1 = Rhoconnect::Model::Base.create(@s2)
    @sa1.class.name.should == 'Rhoconnect::Model::DynamicAdapterModel'
  end

  it "should capture exception in create" do
    Rhoconnect::Model::DynamicAdapterModel.should_receive(:new).once.and_raise(Exception)
    lambda { @sa1 = Rhoconnect::Model::Base.create(@s2) }.should raise_error(Exception)
  end

  it "should fail to create Bro-ken model" do
    broken_source = setup_adapter('Bro-ken')
    lambda { Rhoconnect::Model::Base.create(broken_source) }.should raise_error(Exception)
    broken_source.delete
  end

  it "should create model with trailing spaces" do
    s = setup_adapter('SimpleAdapter ')
    Rhoconnect::Model::Base.create(s).is_a?(SimpleAdapter).should be_true
  end

  describe "model methods" do
    it "should execute Model login method with source vars" do
      @sa.login.should == true
    end

    it "should get Model data (:md)" do
      expected = {'1'=>@product1,'2'=>@product2}
      @s.put_data(:md, expected)
      @sa.get_data.should == expected
    end

    it "should get Model data from specific document" do
      expected = {'4'=>@product1,'5'=>@product2}
      Source.define_valid_doctypes([:md_custom])
      @s.put_data(:md_custom, expected)
      @sa.get_data(:md_custom).should == expected
      Source.valid_doctypes.delete(:md_custom)
    end

    it "should execute Model query method" do
      expected = {'1'=>@product1,'2'=>@product2}
      @sa.inject_result expected
      @sa.query.should == expected
    end

    it "should execute Model search method and modify params" do
      params = {:hello => 'world'}
      expected = {'1'=>@product1,'2'=>@product2}
      @sa.inject_result expected
      @sa.search(params).should == expected
      params.should == {:hello => 'world', :foo => 'bar'}
    end

    it "should execute Model login with current_user" do
      @sa.should_receive(:current_user).with(no_args()).and_return(@u)
      @sa.login
    end

    it "should execute Model sync method" do
      expected = {'1'=>@product1,'2'=>@product2}
      @sa.inject_result expected
      @sa.do_query
      Store.get_data(@s.docname(:md)).should == expected
      Store.get_value(@s.docname(:md_size)).to_i.should == 2
    end

    it "should execute Model sync method with nil result" do
      @sa.inject_result nil
      @sa.do_query
      Store.get_data(@s.docname(:md)).should == {}
    end

    it "should fail gracefully if @result is missing" do
      @sa.inject_result nil
      lambda { @sa.query }.should_not raise_error
    end

    it "should reset count if @result is empty" do
      @sa.inject_result({'1'=>@product1,'2'=>@product2})
      @sa.do_query
      Store.get_value(@s.docname(:md_size)).to_i.should == 2
      @sa.inject_result({})
      @sa.do_query
      Store.get_value(@s.docname(:md_size)).to_i.should == 0
    end

    it "should execute Model create method" do
      @sa.create(@product4).should == 'obj4'
    end

    it "should stash @result in store and set it to nil" do
      expected = {'1'=>@product1,'2'=>@product2}
      Source.define_valid_doctypes(['tmpdoc'.to_sym])
      @sa.inject_result(expected)
      @sa.inject_tmpdoc('tmpdoc')
      @sa.stash_result
      @s.get_data('tmpdoc').should == expected
      Source.valid_doctypes.delete('tmpdoc'.to_sym)
    end

    describe "Model metadata method" do
      it "should execute Model metadata method" do
        mock_metadata_method([SimpleAdapter]) do
          @sa.metadata.should == "{\"foo\":\"bar\"}"
        end
      end
    end
  end
end