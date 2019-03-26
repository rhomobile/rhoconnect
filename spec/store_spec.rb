require File.join(File.dirname(__FILE__),'spec_helper')

describe "Store" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  describe "store methods" do
    it "should create proper connection class" do
      expect(Store.get_store(0).db.class.name).to match(/Redis/)
    end

    it "should create redis connection based on ENV" do
      ENV[REDIS_URL] = 'redis://localhost:6379'
      expect(Redis).to receive(:new).with(:url => 'redis://localhost:6379', :thread_safe => true, :timeout => Rhoconnect.redis_timeout).exactly(1).times.and_call_original
      Store.nullify
      expect(Store.num_stores).to eq(0)
      Store.create
      expect(Store.get_store(0).db).not_to be_nil
      ENV.delete(REDIS_URL)
    end

    it "should create redis connection based on REDISTOGO_URL ENV" do
      ENV[REDISTOGO_URL] = 'redis://localhost:6379'
      expect(Redis).to receive(:new).with(:url => 'redis://localhost:6379', :thread_safe => true, :timeout => Rhoconnect.redis_timeout).exactly(1).and_call_original
      Store.nullify
      Store.create
      Store.get_store(0).db.should_not == nil
      ENV.delete(REDISTOGO_URL)
    end

    it "should add simple data to new set" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data
    end

    it "should set_data and get_data" do
      Store.set_data('foo', @data)
      Store.get_data('foo').should == @data
    end

    it "should put_data with simple data" do
      data = { '1' => { 'hello' => 'world' } }
      Store.put_data('mydata', data)
      Store.get_data('mydata').should == data
    end

    it "should update_objects with simple data and one changed attribute" do
      data = { '1' => { 'hello' => 'world', "attr1" => 'value1' } }
      update_data = { '1' => {'attr1' => 'value2'}}
      Store.put_data(:md, data)
      Store.get_data(:md).should == data
      Store.update_objects(:md, update_data)
      data['1'].merge!(update_data['1'])
      Store.get_data(:md).should == data
    end

    it "should update_objects with simple data and verify that srem and sadd is called only on affected fields" do
      data = { '1' => { 'hello' => 'world', "attr1" => 'value1' } }
      update_data = { '1' => {'attr1' => 'value2', 'new_attr' => 'new_val', 'hello' => 'world'},
                      '2' => {'whole_new_object' => 'new_value' } }
      Store.put_data('mydata', data)
      Store.get_store(0).db.should_receive(:srem).exactly(1).times
      Store.get_store(0).db.should_receive(:sadd).exactly(2).times
      Store.update_objects('mydata', update_data)
    end

    it "should delete_objects with simple data" do
      data = { '1' => { 'hello' => 'world', "attr1" => 'value1' } }
      Store.put_data('mydata', data)
      Store.delete_objects('mydata', ['1'])
      Store.get_data('mydata').should == {}
    end

    it "should update_count and delete_value with simple integer data" do
      Store.put_value('mydata', 21)
      Store.update_count('mydata', -5)
      Store.get_value('mydata').to_i.should == 16
      Store.delete_value('mydata')
      Store.exists?('mydata').should be false
    end

    it "should delete_objects with simple data and verify that srem is called only on affected fields" do
      data = { '1' => { 'hello' => 'world', "attr1" => 'value1' } }
      Store.put_data('mydata', data)
      Store.get_store(0).db.should_receive(:srem).exactly(1).times
      Store.get_store(0).db.should_receive(:sadd).exactly(0).times
      Store.delete_objects('mydata', ['1'])
    end

    it "should add simple array data to new list" do
      @data = ['1','2','3']
      Store.put_list(@s.docname(:md),@data).should == true
      Store.get_list(@s.docname(:md)).should == @data
    end

    it "should add simple array data to new list using *_data methods" do
      @data = ['1','2','3']
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md),Array).should == @data
    end

    it "should replace simple data to existing set" do
      new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
      Store.put_data(@s.docname(:md),@data).should == true
      Store.put_data(@s.docname(:md),new_data)
      Store.get_data(@s.docname(:md)).should == new_data
    end

    it "should put_value and get_value" do
      Store.put_value('foo','bar')
      Store.get_value('foo').should == 'bar'
    end

    it "should incr a key" do
      Store.incr('foo').should == 1
    end

    it "should decr a key" do
      Store.set_value('foo', 10)
      Store.decr('foo').should == 9
    end

    it "should return modified objs in doc2" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data

      @product3['price'] = '59.99'
      elem_3 = Store.get_store(0).send(:set_obj_element, '3', @product3)
      keypairs_3 = Store.get_store(0).send(:get_obj_key_and_pairs, elem_3)
      expected = {elem_3 => keypairs_3}
      @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product3

      Store.put_data(@c.docname(:cd),@data1)
      Store.get_data(@c.docname(:cd)).should == @data1
      Store.get_diff_data(@s.docname(:md),@c.docname(:cd)).should == expected
    end

    it "should return objects with attributes modified and missed in doc2" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data

      mod_product2 = @product2.dup
      mod_product2['price'] = '59.99'
      elem_2 = Store.get_store(0).send(:set_obj_element, '2', @data['2'])
      elem_3 = Store.get_store(0).send(:set_obj_element, '3', @product3)
      keypairs_2 = Store.get_store(0).send(:get_obj_key_and_pairs, elem_2)
      keypairs_3 = Store.get_store(0).send(:get_obj_key_and_pairs, elem_3)
      expected = {elem_2 => keypairs_2, elem_3 => keypairs_3}
      @data1,@data1['1'],@data1['2'] = {},@product1,mod_product2

      Store.put_data(@c.docname(:cd),@data1)
      Store.get_data(@c.docname(:cd)).should == @data1
      Store.get_diff_data(@c.docname(:cd),@s.docname(:md)).should == expected
    end

    it "should ignore reserved attributes" do
      @newproduct = {
        'name' => 'iPhone',
        'brand' => 'Apple',
        'price' => '199.99',
        'id' => 1234,
        'attrib_type' => 'someblob'
      }

      @data1 = {'1'=>@newproduct,'2'=>@product2,'3'=>@product3}

      Store.put_data(@s.docname(:md),@data1).should == true
      Store.get_data(@s.docname(:md)).should == @data
    end

    it "should flush_data" do
      Store.put_data(@s.docname(:md),@data)
      Store.flush_data(@s.docname(:md))
      Store.get_data(@s.docname(:md)).should == {}
    end

    it "should flush_data for all keys matching pattern" do
      keys = ['test_flush_data1','test_flush_data2']
      keys.each {|key| Store.put_data(key,@data)}
      Store.flush_data('test_flush_data*')
      keys.each {|key| Store.get_data(key).should == {} }
    end

    it "should flush_data without calling KEYS when there aren't pattern matching characters in the provided keymask" do
      key = 'test_flush_data'
      Store.put_data(key,@data)
      redis_client = Store.get_store(0).db
      expect(redis_client).to receive(:del).once.with("#{key}:#{get_sha1('1')[0..1]}").and_return(true)
      expect(redis_client).to receive(:del).once.with("#{key}:#{get_sha1('2')[0..1]}").and_return(true)
      expect(redis_client).to receive(:del).once.with("#{key}:#{get_sha1('3')[0..1]}").and_return(true)
      expect(redis_client).to receive(:del).once.with("#{key}:indices").and_return(true)
      expect(redis_client).to receive(:del).once.with("#{key}").and_return(true)

      Store.flush_data(key)
    end

    it "should flush_data and call KEYS when there are pattern matching characters in the provided keymask" do
      keys = ['test_flush_data1','test_flush_data2']
      keys.each {|key| Store.put_data(key,@data)}
      docs = Store.keys("test_flush_data*")
      Store.get_store(0).db.should_receive(:keys).exactly(1).times.with("test_flush_data*").and_return(docs)
      Store.get_store(0).db.should_receive(:del).exactly(8).times.and_return(true)
      Store.flush_data("test_flush_data*")
    end

    it "should put_zdata and get_zdata" do
      create_doc = [[@s.name, [['1', {'foo' => 'bar'}]]]]
      assoc_key = 'my_assoc_key'
      Store.put_zdata('doc1',assoc_key,create_doc)
      zdata,keys = Store.get_zdata('doc1')
      zdata.should == [create_doc]
      keys.should == [assoc_key]
    end

    it "should return empty list on non-existing get_zdata" do
      zdata,keys = Store.get_zdata('wrong_doc2')
      zdata.should == []
      keys.should == []
    end

    it "should append duplicate data in put_zdata" do
      create_doc = [[@s.name, [['1', {'foo' => 'bar'}]]]]
      assoc_key = 'my_assoc_key'
      Store.put_zdata('doc1',assoc_key,create_doc)
      Store.put_zdata('doc1',assoc_key,create_doc, true)
      zdata,keys = Store.get_zdata('doc1')
      zdata.should == [create_doc,create_doc]
      keys.should == [assoc_key,assoc_key]
    end

    it "should flush_zdata" do
      create_doc = [[@s.name, [['1', {'foo' => 'bar'}]]]]
      assoc_key = 'my_assoc_key'
      Store.put_zdata('doc1',assoc_key,create_doc)
      zdocs = Store.get_data("doc1:1:my_assoc_key:#{@s.name}:0")
      zdocs.should == {'0_1' => {'foo' => 'bar'}}
      Store.flush_zdata('doc1')
      zdata,keys = Store.get_zdata('doc1')
      zdata.should == []
      keys.should == []
      zdocs = Store.get_data("doc1:1:my_assoc_key:#{@s.name}:0")
      zdocs.should == {}
    end

    if defined?(JRUBY_VERSION)
      it "should lock document" do
        doc = "locked_data"
        threads = []
        m_lock = Store.get_lock(doc)
        threads << Thread.new do
          t_lock = Store.get_lock(doc)
          Store.put_data(doc,{'1'=>@product1},true)
          Store.release_lock(doc,t_lock)
        end
        threads << Thread.new do
          t_lock = Store.get_lock(doc)
          Store.put_data(doc,{'3'=>@product3},true)
          Store.release_lock(doc,t_lock)
        end
        Store.put_data(doc,{'2'=>@product2},true)
        Store.get_data(doc).should == {'2'=>@product2}
        Store.release_lock(doc,m_lock)
        threads.each { |t| t.join }
        m_lock = Store.get_lock(doc)
        Store.get_data(doc).should == {'1'=>@product1,'2'=>@product2,'3'=>@product3}
      end
    else
      it "should lock document" do
        doc = "locked_data"
        m_lock = Store.get_lock(doc)
        pid = Process.fork do
          Store.nullify
          Store.create
          t_lock = Store.get_lock(doc)
          Store.put_data(doc,{'1'=>@product1},true)
          Store.release_lock(doc,t_lock)
          Process.exit(0)
        end
        Store.put_data(doc,{'2'=>@product2},true)
        Store.get_data(doc).should == {'2'=>@product2}
        Store.release_lock(doc,m_lock)
        Process.waitpid(pid)
        m_lock = Store.get_lock(doc)
        Store.get_data(doc).should == {'1'=>@product1,'2'=>@product2}
      end
    end

    it "should lock key for timeout" do
      doc = "locked_data"
      lock = Time.now.to_i+3
      Store.get_store(0).db.set "lock:#{doc}", lock
      expect(Store.get_store(0)).to receive(:sleep).at_least(:once).with(1) { sleep 1; Store.release_lock(doc,lock); }
      Store.get_lock(doc,4)
    end

    it "should raise exception if lock expires" do

      doc = "locked_data"
      Store.get_lock(doc)
      lambda { sleep 2; Store.get_lock(doc,4,true) }.should raise_error(StoreLockException,"Lock \"lock:locked_data\" expired before it was released")
    end

    it "should raise lock expires exception on global setting" do
      doc = "locked_data"
      Store.get_lock(doc)
      Rhoconnect.raise_on_expired_lock = true
      lambda { sleep 2; Store.get_lock(doc,4) }.should raise_error(StoreLockException,"Lock \"lock:locked_data\" expired before it was released")
      Rhoconnect.raise_on_expired_lock = false
    end

    it "should acquire lock if it expires" do
     	doc = "locked_data"
     	Store.get_lock(doc)
     	sleep 2
     	Store.get_lock(doc,1).should > Time.now.to_i
    end

    it "should use global lock duration" do
      doc = "locked_data"
      Rhoconnect.lock_duration = 2
     	Store.get_lock(doc)
     	expect(Store.get_store(0)).to receive(:sleep).at_least(1).times.with(1) { sleep 1 }
      Store.get_lock(doc)
     	Rhoconnect.lock_duration = nil
    end

    it "should lock document in block" do
      doc = "locked_data"
      Store.lock(doc,0) do
        Store.put_data(doc,{'2'=>@product2})
        Store.get_data(doc).should == {'2'=>@product2}
      end
    end

    it "should create clone of set" do
      set_state('abc' => @data)
      Store.clone('abc','def')
      verify_result('abc' => @data,'def' => @data)
    end

    it "should rename a key" do
      set_state('key1' => @data)
      Store.rename('key1','key2')
      verify_result('key1' => {}, 'key2' => @data)
    end

    it "should not fail to rename if key doesn't exist" do
      Store.rename('key1','key2')
      Store.exists?('key1').should be false
      Store.exists?('key2').should be false
    end

    it "should raise ArgumentError on put_data with invalid data" do
      foobar = {'foo'=>'bar'}
      expect {
        Store.put_data('somedoc',{'foo'=>'bar'})
      }.to raise_exception(ArgumentError, "Invalid value object: #{foobar['foo'].inspect}. Hash is expected.")
    end

    it "should put_object into the bucketed md" do
      key1 = '1'
      data1 = {'foo' => 'bar'}
      key2 = '2'
      data2 = {'one' => 'two', 'three' => 'four'}
      docindex1 = get_sha1(key1)[0..1]
      docindex2 = get_sha1(key2)[0..1]
      Store.put_object(:md, key1, data1)
      Store.put_object(:md, key2, data2)
      Store.keys(:md).should == []
      Store.exists?("#{:md}:#{docindex1}").should be  true
      Store.exists?("#{:md}:#{docindex2}").should be  true
      Store.exists?("#{:md}:indices").should be  true
      Store.get_store(0).db.hkeys("#{:md}:indices").should == ["#{docindex1}", "#{docindex2}"]
      Store.get_store(0).db.hvals("#{:md}:indices").should == ["#{:md}:#{docindex1}", "#{:md}:#{docindex2}"]
    end

    it "should get_object from the bucketed md" do
      key1 = '1'
      data1 = {'foo' => 'bar'}
      key2 = '2'
      data2 = {'one' => 'two', 'three' => 'four'}
      docindex1 = get_sha1(key1)[0..1]
      docindex2 = get_sha1(key2)[0..1]
      Store.put_object(:md, key1, data1)
      Store.put_object(:md, key2, data2)
      obj2 = Store.get_object(:md, key2)
      obj2.should == data2
    end

    it "should make temporary document and restore it to permanent with rename" do
      key1 = '1'
      data1 = {'foo' => 'bar'}
      key2 = '2'
      data2 = {'one' => 'two', 'three' => 'four'}
      docindex1 = get_sha1(key1)[0..1]
      docindex2 = get_sha1(key2)[0..1]
      Store.put_tmp_data(:md, {key1 => data1})
      Store.put_tmp_data(:md, {key2 => data2}, true)

      Store.exists?("#{:md}:#{docindex1}").should be  true
      Store.exists?("#{:md}:#{docindex2}").should be  true
      Store.exists?("#{:md}:indices").should be  true
      Store.get_store(0).db.ttl("#{:md}:#{docindex1}").should == Rhoconnect.store_key_ttl
      Store.get_store(0).db.ttl("#{:md}:#{docindex2}").should == Rhoconnect.store_key_ttl
      Store.get_store(0).db.ttl("#{:md}:indices").should == Rhoconnect.store_key_ttl

      Store.rename_tmp_data(:md, :md_perm)
      Store.exists?("#{:md}:#{docindex1}").should be false
      Store.exists?("#{:md}:#{docindex2}").should be false
      Store.exists?("#{:md}:indices").should be false
      Store.exists?("#{:md_perm}:#{docindex1}").should be  true
      Store.exists?("#{:md_perm}:#{docindex2}").should be  true
      Store.exists?("#{:md_perm}:indices").should be  true
      Store.get_store(0).db.ttl("#{:md_perm}:#{docindex1}").should == -1
      Store.get_store(0).db.ttl("#{:md_perm}:#{docindex2}").should == -1
      Store.get_store(0).db.ttl("#{:md_perm}:indices").should == -1
    end

    describe "multiple redis clustering" do
      before(:all) do
        # start 2 redis instances in addition to default 6379
        system("redis-server --port 6380 &")
        system("redis-server --port 6381 &")
        sleep(1)
        Store.nullify
        Store.create(['localhost:6379', 'localhost:6380', 'localhost:6381'])

      end

      after(:all) do
        # shutdown 2 additional redis instances (leave default one as is)
        Store.get_store(1).send(:db).shutdown
        Store.get_store(2).send(:db).shutdown
        Store.nullify
      end

      it "should list number of stores" do
        Store.num_stores.should == 3
      end

      it "data for Source and Client docs should be on the same instance" do
        source_index = @s.store_index(:md)
        client_index = @c.store_index(:cd)
        # for this source and user , index should be computed to 2
        source_index.should == 2
        source_index.should == client_index
      end

      it "data for app-parttion should go to system Redis (with index 0)" do
        @c.source_name = @s3.name
        source_index = @s3.store_index(:md)
        client_index = @c.store_index(:cd)
        # for this source and user , index should be compured to 0
        source_index.should == 0
        source_index.should == client_index
      end

      it "should set and flush the data only in appropriate instance" do
        key1 = '1'
        data1 = {'foo' => 'bar'}
        key2 = '2'
        data2 = {'foo1' => 'bar1'}
        @s.put_data(:md, {key1 => data1})
        Store.get_store(2).get_data(@s.docname(:md)).should == {key1 => data1}
        # data in store 1 should not be accessible through Source documents
        # because this combination of user and source should index to instance #2
        Store.get_store(1).put_data(@s.docname(:md), {key2 => data2})
        Store.get_store(1).get_data(@s.docname(:md)).should == {key2 => data2}

        @s.get_data(:md).should == {key1 => data1}
        Store.get_store(2).flush_data(@s.docname(:md))
        @s.get_data(:md).should == {}
        Store.get_store(1).get_data(@s.docname(:md)).should == {key2 => data2}
      end
    end
  end
end
