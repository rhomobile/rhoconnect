require File.join(File.dirname(__FILE__),'perf_spec_helper')

describe "Rhoconnect Performance" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => false

  it "should process get/put/delete for 10000 records (60000 elements)" do
    @data = get_test_data(10000)
    start = start_timer
    Store.put_data('mdoc',@data).should == true
    start = lap_timer('put_data duration',start)
    Store.get_data('mdoc').should == @data
    start = lap_timer('get_data duration',start)
    Store.rename('mdoc','mdoc_copy')
    start = lap_timer("rename doc duration", start)
    Store.clone('mdoc_copy','mdoc_copy1')
    start = lap_timer("clone doc duration", start)
    Store.delete_objects('mdoc_copy',@data.keys[0,2])
    start = lap_timer("delete_objects duration", start)
    Store.delete_data('mdoc_copy1',@data)
    start = lap_timer("delete_data duration", start)
  end

  it "should process update_objects in a set of 10000 records (60000 elements)" do
    @data = get_test_data(10000)
    updated_key = @data.keys[21]
    @update_data = {}
    @update_data[updated_key] = @data[updated_key].clone
    @update_data[updated_key]['Phone'] = 'updated phone SADD'
    @update_data[updated_key]['Phone1'] = 'updated phone SREM and SADD'
    expected = @data.clone
    expected.merge!(@update_data)

    Store.put_data('mdoc',@data).should == true
    start = start_timer
    Store.update_objects('mdoc', @update_data)
    lap_timer("update_objects duration", start)
    Store.get_data('mdoc').should == expected
  end

  it "should process 1000 update_objects in a set of 10000 records (60000 elements)" do
    @data = get_test_data(10000)
    updated_keys = @data.keys[2001..3000]
    @update_data = {}
    updated_keys.each do |updated_key|
      @update_data[updated_key] = @data[updated_key].clone
      @update_data[updated_key]['Phone'] = 'updated phone SADD'
      @update_data[updated_key]['Phone1'] = 'updated phone SREM and SADD'
    end
    expected = @data.dup
    expected.merge!(@update_data)

    Store.put_data('mdoc',@data).should == true
    start = start_timer
    Store.update_objects('mdoc', @update_data)
    lap_timer("update_objects duration", start)

    Store.get_data('mdoc').should == expected
  end

  it "should process single attribute diff for 10000-record doc" do
    @data = get_test_data(10000)
    @data1 = get_test_data(10000)
    @data1['950']['Phone1'] = 'This is changed'
    expected = {'950' => {'Phone1' => 'This is changed'}}
    @s.put_data(:md,@data1).should == true
    @c.put_data(:cd,@data).should == true
    start = start_timer
    cs = create_sync_handler
    token,progress_count,total_count,res = cs.send_new_page
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == expected
    res['insert'].should == expected
    res['delete'].should == {'950' => {'Phone1' => @data['950']['Phone1']}}
  end

  it "should process single attribute diff for 10000-record doc using brute-force approach" do
    @data = get_test_data(10000)
    @data1 = get_test_data(10000)
    @data1['950']['Phone1'] = 'This is changed'
    expected = {'950' => {'Phone1' => 'This is changed'}}
    @s.put_data(:md,@data1).should == true
    @c.put_data(:cd,@data).should == true
    start = start_timer
    cs = create_sync_handler
    token,progress_count,total_count,res = cs.send_new_page_bruteforce
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == expected
    res['insert'].should == expected
    res['delete'].should == {'950' => {'Phone1' => @data['950']['Phone1']}}
  end

  it "should process full-sync for 5000-record doc" do
    @data = get_test_data(5000)
    @s.put_data(:md,@data).should == true
    start = start_timer
    params = { :p_size => 5000 }
    cs = create_sync_handler params
    token,progress_count,total_count,res = cs.send_new_page
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == @data
    res['insert'].should == @data
    res['delete'].should == nil
  end

  it "should process full-sync for 5000-record doc using brute-force approach" do
    @data = get_test_data(5000)
    @s.put_data(:md,@data).should == true
    start = start_timer
    params = { :p_size => 5000 }
    cs = create_sync_handler params
    token,progress_count,total_count,res = cs.send_new_page_bruteforce
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == @data
    res['insert'].should == @data
    res['delete'].should == nil
  end

  it "should process worst-case sync scenario there every attrib of every object is changed for 5000-record doc" do
    @data = generate_fake_data(5000,true)
    sleep(1.5)
    @data1 = generate_fake_data(5000,true)
    @s.put_data(:md,@data).should == true
    @c.put_data(:cd,@data1).should == true
    start = start_timer
    params = { :p_size => 5000 }
    cs = create_sync_handler params
    token,progress_count,total_count,res = cs.send_new_page
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == @data
    @c.get_data(:cd).should == @s.get_data(:md)
    res['insert'].should == @data
    res['delete'].should == @data1
  end

  it "should process worst-case sync scenario there every attrib of every object is changed for 5000-record doc using brute-force approach" do
    @data = generate_fake_data(5000,true)
    sleep(1.5)
    @data1 = generate_fake_data(5000,true)
    @s.put_data(:md,@data).should == true
    @c.put_data(:cd,@data1).should == true
    start = start_timer
    params = { :p_size => 5000 }
    cs = create_sync_handler params
    token,progress_count,total_count,res = cs.send_new_page_bruteforce
    lap_timer('compute_page duration', start)
    @c.get_data(:page).should == @data
    @c.get_data(:cd).should == @s.get_data(:md)
    res['insert'].should == @data
    res['delete'].should == @data1
  end

  # helper
  def create_sync_handler(params = {})
    rh = lambda { @model.do_query(params[:query]) }
    @model = Rhoconnect::Model::Base.create(@s)
    Rhoconnect::Handler::Query::Runner.new(@model, @c, rh, params)
  end
end