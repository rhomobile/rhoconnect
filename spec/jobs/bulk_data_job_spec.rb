require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkDataJob" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  after(:each) do
    delete_data_directory
  end

  let(:mock_schema) { {"property" => { "name" => "string", "brand" => "string" }, "version" => "1.0"} }

  it "should create bulk data files from master document" do
    set_state('test_db_storage' => @data)
    docname = bulk_data_docname(@a.id,@u.id)
    expected = { @s_fields[:name] => @data,
      'FixedSchemaAdapter' => @data
    }
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :partition_sources => [@s_fields[:name],'FixedSchemaAdapter'],
      :sources => [@s_fields[:name], 'FixedSchemaAdapter'])
    do_bulk_data_job("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_doc_result(@s, {:md => @data,
                           :md_copy => @data})
    validate_db(data,expected).should == true
    File.exists?(data.dbfile+'.rzip').should == true
    File.exists?(data.dbfile+'.gzip').should == true
    path = File.join(File.dirname(data.dbfile),'tmp')
    FileUtils.mkdir_p path
    unzip_file("#{data.dbfile}.rzip",path)
    data.dbfile = File.join(path,File.basename(data.dbfile))
    validate_db(data,expected).should == true
  end

  it "should create bulk data files from master document for specific sources" do
    set_state('test_db_storage' => @data)
    docname = bulk_data_docname(@a.id,@u.id)
    expected = { @s_fields[:name] => {},
      'FixedSchemaAdapter' => @data
    }
    source_existing_data = {'my_key1' => {'my_attrib1' => 'my_val1'}}
    @s.put_data(:md, source_existing_data)
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :partition_sources => [@s_fields[:name],'FixedSchemaAdapter'],
      :sources => ['FixedSchemaAdapter'])
    do_bulk_data_job("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_doc_result(@s, {:md => source_existing_data,
                           :md_copy => {}})
    # skipped source should have :none in the DB - so we pass it for verification
    @s.sync_type = :none
    validate_db_file(data.dbfile,[@s_fields[:name], 'FixedSchemaAdapter'], expected).should == true
    File.exists?(data.dbfile+'.rzip').should == true
    File.exists?(data.dbfile+'.gzip').should == true
    path = File.join(File.dirname(data.dbfile),'tmp')
    FileUtils.mkdir_p path
    unzip_file("#{data.dbfile}.rzip",path)
    data.dbfile = File.join(path,File.basename(data.dbfile))
    validate_db_file(data.dbfile,[@s_fields[:name], 'FixedSchemaAdapter'], expected).should == true
  end

  it "should create sqlite data with source metadata" do
    set_state('test_db_storage' => @data)
    mock_metadata_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :partition_sources => [@s_fields[:name]],
        :sources => [@s_fields[:name]])
      do_bulk_data_job("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_doc_result(@s, {:md => @data,
                             :metadata => {'foo'=>'bar'}.to_json,
                             :md_copy => @data})
      validate_db(data,@s.name => @data).should == true
    end
  end

  it "should create sqlite data with source schema" do
    set_state('test_db_storage' => @data)
    mock_schema_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :partition_sources => [@s_fields[:name]],
        :sources => [@s_fields[:name]])
      do_bulk_data_job("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_doc_result(@s, {:md => @data,
                           :md_copy => @data})
      JSON.parse(@s.get_value(:schema)).should == mock_schema
      validate_db(data,@s.name => @data).should == true
    end
  end

  it "should delete bulk data if exception is raised" do
    lambda {
      do_bulk_data_job("data_name" => 'broken')
    }.should raise_error(Exception)
    Store.get_store(0).db.keys('bulk_data*').should == []
  end

  it "should delete bulk data if exception is raised" do
    data = BulkData.create(:name => bulk_data_docname('broken',@u.id),
      :state => :inprogress,
      :app_id => 'broken',
      :user_id => @u.id,
      :partition_sources => [@s_fields[:name]],
      :sources => [@s_fields[:name]])
    lambda {
      do_bulk_data_job("data_name" => data.name)
    }.should raise_error(Exception)
    Store.get_store(0).db.keys('bulk_data*').should == []
  end
end