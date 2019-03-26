require File.join(File.dirname(__FILE__),'spec_helper')

STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

describe "User" do
  include_examples "SharedRhoconnectHelper", :rhoconnect_data => true

  it "should not allow user created with reserved login" do
    Store.get_value('user:count').should == "2"
    lambda {
      User.create({:login => '__shared__'})
      }.should raise_error(ArgumentError, 'Reserved user id __shared__')
    Store.get_value('user:count').should == "2"
  end

  it "should load user with fields" do
    @u.id.should == @u_fields[:login]
    @u1 = User.load(@u_fields[:login])
    @u1.id.should == @u.id
    @u1.login.should == @u_fields[:login]
    @u1.email.should == @u_fields[:email]
    Store.get_value('user:count').should == "2"
  end

  it "should create token for user" do
    token = @u.create_token
    token.length.should == 32
    ApiToken.load(token).user_id.should == @u.id
  end

  it "should get token for user" do
    token = @u.create_token
    @u.token.value.length.should == 32
    @u.token.value.should == token
  end

  it "should use token provisioned in settings if one" do
    token = User.load('rhoadmin').token_id
    token.should == Rhoconnect.api_token
    ApiToken.is_exist?(token).should == true
  end

  it "should delete token if one exists" do
    token = @u.create_token
    ApiToken.is_exist?(token).should == true
    token2 = @u.create_token
    ApiToken.is_exist?(token).should == false
    ApiToken.is_exist?(token2).should == true
  end

  it "should assign token to existing user" do
    token = @u.create_token
    @u.token = 'foo'
    @u.token.value.should == 'foo'
    ApiToken.is_exist?('foo').should == true
    ApiToken.is_exist?(token).should == false
  end

  it "should authenticate with proper credentials" do
    @u1 = User.authenticate(@u_fields[:login],'testpass')
    @u1.should_not be_nil
    @u1.login.should == @u_fields[:login]
    @u1.email.should == @u_fields[:email]
  end

  it "should fail to authenticate with invalid credentials" do
    User.authenticate(@u_fields[:login],'wrongpass').should be_nil
  end

  it "should fail to authenticate with nil user" do
    User.authenticate('niluser','doesnotmatter').should be_nil
  end

  it "should delete user and user clients" do
    @c.put_data(:cd,@data)
    cid = @c.id
    @u.delete
    Store.get_value('user:count').should == "1"
    User.is_exist?(@u_fields[:login]).should == false
    Client.is_exist?(cid).should == false
    @c.get_data(:cd).should == {}
  end

  it "should delete token for user" do
    token = @u.create_token
    @u.delete
    ApiToken.is_exist?(token).should == false
  end

  describe "User Stats" do

    before(:each) do
      allow(Store).to receive(:lock).and_yield
    end

    it "should increment user stats on create" do
      Time.stub(:now).and_return(10)
      Rhoconnect.stats = true
      User.create({:login => 'testuser2'})
      Rhoconnect::Stats::Record.range('users',0,-1).should == ["3:10"]
      Store.get_value('user:count').should == "3"
      Rhoconnect.stats = false
    end

    it "should decrement user stats on delete" do
      Time.stub(:now).and_return(10)
      Rhoconnect.stats = true
      u = User.create({:login => 'testuser1'})
      Rhoconnect::Stats::Record.range('users',0,-1).should == ["3:10"]
      u.delete
      Rhoconnect::Stats::Record.range('users',0,-1).should == ["2:10"]
      Store.get_value('user:count').should == "2"
      Rhoconnect.stats = false
    end
  end
end
