# Taken from http://github.com/voloko/redis-model
require File.join(File.dirname(__FILE__), 'spec_helper')

describe Rhoconnect::StoreOrm do

  context "DSL" do
    class TestDSL < Rhoconnect::StoreOrm
      field :foo
      list :bar
      set :sloppy
    end

    before(:each) do
      @x = TestDSL.with_key(1)
    end

    it "should define rw accessors for field" do
      expect(@x).to respond_to(:foo)
      expect(@x).to respond_to(:foo=)
    end

    it "should define r accessor for list" do
      expect(@x).to respond_to(:bar)
    end

    it "should define r accessor for set" do
      expect(@x).to respond_to(:sloppy)
    end

    it "should raise error on invalid type" do
      expect(lambda do
        class TestInvalidType < Rhoconnect::StoreOrm
          field :invalid, :invalid_type
        end
      end).to raise_error(ArgumentError, 'Unknown type invalid_type for field invalid')
    end
  end

  context "field type cast" do
    class TestType < Rhoconnect::StoreOrm
      field :foo_string, :string
      field :foo_json, :json
      field :foo_date, :datetime
      field :foo_int, :int
      field :foo_float, :float

      list :list_date, :datetime
      set :set_date, :datetime
    end

    class TestValidateType < Rhoconnect::StoreOrm
      field :v_field, :string
      validates_presence_of :v_field
    end

    class TestLoadType < Rhoconnect::StoreOrm
      field :something, :string
      attr_accessor :foo
    end

    before(:each) do
      Store.create
      Store.flush_all
=begin
      @xRedisMock = RSpec::Mocks::Mock.new
      @yRedisMock = RSpec::Mocks::Mock.new
      @xRedisDbMock = RSpec::Mocks::Mock.new
      @yRedisDbMock = RSpec::Mocks::Mock.new
=end
      @x = TestType.with_key(1)
      @y = TestType.with_key(1)
      allow(@x).to receive(:store).and_return(@xRedisMock)
      allow(@y).to receive(:store).and_return(@yRedisMock)
      allow(@xRedisMock).to receive(:db).and_return(@xRedisDbMock)
      allow(@yRedisMock).to receive(:db).and_return(@yRedisDbMock)
    end

    it "should create with string id" do
      @x = TestType.create(:id => 'test')
      expect(@x.id).to eq('test')
    end

    it "should create with auto-increment id" do
      @x = TestType.create
      @x1 = TestType.create
      expect(@x1.id).to eq(@x.id + 1)
    end

    it "should raise ArgumentError on create with duplicate id" do
      @x = TestType.create(:id => 'test1')
      expect(lambda {TestType.create(:id => 'test1') }).to raise_error(ArgumentError, "Record already exists for 'test1'")
    end

    it "should validate_presence_of v_field" do
      expect(lambda {TestValidateType.create(:id => 'test2')}).to raise_error(ArgumentError, "Missing required field 'v_field'")
    end

    it "should load with attributes set" do
      TestLoadType.create(:id => 'test2')
      @x = TestLoadType.load('test2', {:foo => 'bar'})
      expect(@x.foo).to eq('bar')
    end

    it "should save string as is" do
      expect(@xRedisMock).to receive(:put_value).with('test_type:1:foo_string', 'xxx')
      expect(@yRedisMock).to receive(:get_value).with('test_type:1:foo_string').and_return('xxx')
      @x.foo_string = 'xxx'
      expect(@y.foo_string).to be_instance_of(String)
    end

    it "should marshal integer fields" do
      expect(@xRedisMock).to receive(:put_value).with('test_type:1:foo_int', '12')
      expect(@yRedisMock).to receive(:get_value).with('test_type:1:foo_int').and_return('12')
      @x.foo_int = 12
      expect(@y.foo_int).to be_kind_of(Integer)
      expect(@y.foo_int).to eq(12)
    end

    it "should marshal float fields" do
      expect(@xRedisMock).to receive(:put_value).with('test_type:1:foo_float', '12.1')
      expect(@yRedisMock).to receive(:get_value).with('test_type:1:foo_float').and_return('12.1')
      @x.foo_float = 12.1
      expect(@y.foo_float).to be_kind_of(Float)
      expect(@y.foo_float).to eq(12.1)
    end

    it "should marshal datetime fields" do
      time = DateTime.now
      str = time.strftime('%FT%T%z')
      expect(@xRedisMock).to receive(:put_value).with('test_type:1:foo_date', str)
      expect(@yRedisMock).to receive(:get_value).with('test_type:1:foo_date').and_return(str)
      @x.foo_date = time
      expect(@y.foo_date).to be_kind_of(DateTime)
      expect(@y.foo_date.to_s).to eq(time.to_s)
    end

    it "should marshal json structs" do
      data = {'foo' => 'bar', 'x' => 2}
      str = JSON.dump(data)
      expect(@xRedisMock).to receive(:put_value).with('test_type:1:foo_json', str)
      expect(@yRedisMock).to receive(:get_value).with('test_type:1:foo_json').and_return(str)
      @x.foo_json = data
      expect(@y.foo_json).to be_kind_of(Hash)
      expect(@y.foo_json.inspect).to eq(data.inspect)
    end

    it "should return nil for empty fields" do
      expect(@xRedisMock).to receive(:get_value).with('test_type:1:foo_date').and_return(nil)
      expect(@x.foo_date).to be_nil
    end

    it "should marshal list values" do
      data = DateTime.now
      str = data.strftime('%FT%T%z')

      expect(@xRedisDbMock).to receive('rpush').with('test_type:1:list_date', str)
      expect(@xRedisDbMock).to receive('lset').with('test_type:1:list_date', 1, str)
      expect(@xRedisDbMock).to receive('exists').with('test_type:1:list_date', str)
      expect(@xRedisDbMock).to receive('lrem').with('test_type:1:list_date', 0, str)
      expect(@xRedisDbMock).to receive('lpush').with('test_type:1:list_date', str)
      expect(@xRedisDbMock).to receive('lrange').with('test_type:1:list_date', 0, 1).and_return([str])
      expect(@xRedisDbMock).to receive('rpop').with('test_type:1:list_date').and_return(str)
      expect(@xRedisDbMock).to receive('lpop').with('test_type:1:list_date').and_return(str)
      expect(@xRedisDbMock).to receive('lindex').with('test_type:1:list_date', 0).and_return(str)
      @x.list_date << data
      @x.list_date[1] = data
      @x.list_date.include?(data)
      @x.list_date.remove(0, data)
      @x.list_date.push_head(data)
      expect(@x.list_date[0]).to be_kind_of(DateTime)
      expect(@x.list_date[0, 1][0]).to be_kind_of(DateTime)
      expect(@x.list_date.pop_tail).to be_kind_of(DateTime)
      expect(@x.list_date.pop_head).to be_kind_of(DateTime)
    end

    it "should marshal set values" do
      data = DateTime.now
      str = data.strftime('%FT%T%z')

      expect(@xRedisDbMock).to receive('sadd').with('test_type:1:set_date', str)
      expect(@xRedisDbMock).to receive('srem').with('test_type:1:set_date', str)
      expect(@xRedisDbMock).to receive('sismember').with('test_type:1:set_date', str)
      expect(@xRedisDbMock).to receive('smembers').with('test_type:1:set_date').and_return([str])
      @x.set_date << data
      @x.set_date.delete(data)
      @x.set_date.include?(data)
      expect(@x.set_date.members[0]).to be_kind_of(DateTime)
    end

    it "should handle empty members" do
      allow(@xRedisDbMock).to receive(:smembers).and_return(nil)
      expect(@x.set_date.members).to eq([])
    end
  end

  context "increment/decrement" do
    class TestIncrements < Rhoconnect::StoreOrm
      field :foo, :integer
      field :bar, :string
      field :baz, :float
    end

    before do
      #@redisMock = RSpec::Mocks::Mock.new
      @redisMock
      @x = TestIncrements.with_key(1)
      allow(@x).to receive(:store).and_return(@redisMock)
    end

    it "should send INCR when #increment! is called on an integer" do
      expect(@redisMock).to receive(:update_count).with("test_increments:1:foo", 1)
      @x.increment!(:foo)
    end

    it "should send DECR when #decrement! is called on an integer" do
      expect(@redisMock).to receive(:update_count).with("test_increments:1:foo", -1)
      @x.decrement!(:foo)
    end

    it "should raise an ArgumentError when called on non-integers" do
      [:bar, :baz].each do |f|
        expect(lambda {@x.increment!(f)}).to raise_error(ArgumentError)
        expect(lambda {@x.decrement!(f)}).to raise_error(ArgumentError)
      end
    end
  end

  context "redis commands" do
    class TestCommands < Rhoconnect::StoreOrm
      field :foo
      list :bar
      set :sloppy
    end

    before(:each) do
      # @redisMock = RSpec::Mocks::Mock.new
      # @redisDbMock = RSpec::Mocks::Mock.new
      @redisMock
      @redisDbMock
      @x = TestCommands.with_key(1)
      allow(@x).to receive(:store).and_return(@redisMock)
      allow(@redisMock).to receive(:db).and_return(@redisDbMock)
    end

    it "should send GET on field read" do
      expect(@redisMock).to receive(:get_value).with('test_commands:1:foo')
      @x.foo
    end

    it "should send SET on field write" do
      expect(@redisMock).to receive(:put_value).with('test_commands:1:foo', 'bar')
      @x.foo = 'bar'
    end

    it "should send RPUSH on list <<" do
      expect(@redisDbMock).to receive(:rpush).with('test_commands:1:bar', 'bar')
      @x.bar << 'bar'
    end

    it "should send SADD on set <<" do
      expect(@redisDbMock).to receive(:sadd).with('test_commands:1:sloppy', 'bar')
      @x.sloppy << 'bar'
    end

    it "should delete separate fields" do
      expect(@redisMock).to receive(:delete_value).with('test_commands:1:foo')
      @x.delete :foo
    end

    it "should delete all field" do
      expect(@redisMock).to receive(:delete_value).with('test_commands:1:foo')
      expect(@redisMock).to receive(:delete_value).with('test_commands:1:rho__id')
      expect(@redisMock).to receive(:delete_value).with('test_commands:1:bar')
      expect(@redisMock).to receive(:delete_value).with('test_commands:1:sloppy')
      @x.delete
    end
  end
end
