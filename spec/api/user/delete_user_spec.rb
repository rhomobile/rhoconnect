require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhoconnectApiDeleteUser" do
  include_examples "ApiHelper"

  it "should delete user" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    User.is_exist?(params[:attributes][:login]).should == true

    #set up two users with data for the same source
    params2 = {:app_id => APP_NAME,:user_id => 'testuser1'}
    params3 = {:app_id => APP_NAME,:user_id => 'testuser'}
    time = Time.now.to_i
    s  = Source.load('SampleAdapter', params2)
    s.read_state.refresh_time = time
    s2 = Source.load('SampleAdapter', params3)
    s2.read_state.refresh_time = time
    Source.define_valid_doctypes([:doc1])
    set_doc_state(s, :doc1 => {'4'=>@product4})
    set_doc_state(s2, :doc1 => {'4'=>@product4})
    verify_doc_result(s, :doc1 => {'4'=>@product4})
    verify_doc_result(s2, :doc1 => {'4'=>@product4})

    delete "/rc/#{Rhoconnect::API_VERSION}/users/#{params[:attributes][:login]}", {}, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    verify_doc_result(s, :doc1 => {})
    verify_doc_result(s2, :doc1 => {'4'=>@product4})
    s.load_read_state.should == nil
    s2.load_read_state.refresh_time.should == time
    User.is_exist?(params[:attributes][:login]).should == false
    App.load(test_app_name).users.members.should == ["testuser"]
    Source.valid_doctypes.delete(:doc1)
  end

  it "should delete user and print deprecation warning with the old route" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/rc/#{Rhoconnect::API_VERSION}/users", params, {Rhoconnect::API_TOKEN_HEADER => @api_token}
    last_response.should be_ok
    User.is_exist?(params[:attributes][:login]).should == true

    #set up two users with data for the same source
    params2 = {:app_id => APP_NAME,:user_id => 'testuser1'}
    params3 = {:app_id => APP_NAME,:user_id => 'testuser'}
    time = Time.now.to_i
    s  = Source.load('SampleAdapter', params2)
    s.read_state.refresh_time = time
    s2 = Source.load('SampleAdapter', params3)
    s2.read_state.refresh_time = time
    Source.define_valid_doctypes([:doc1])
    set_state(s.docname(:doc1) => {'4'=>@product4})
    set_state(s2.docname(:doc1) => {'4'=>@product4})
    verify_result(s.docname(:doc1) => {'4'=>@product4})
    verify_result(s2.docname(:doc1) => {'4'=>@product4})
    post "/api/delete_user", {:api_token => @api_token, :user_id => params[:attributes][:login]}
    last_response.should be_ok
    last_response.headers['Warning'].index('deprecated').should_not == nil
    verify_result(s.docname(:doc1) => {})
    verify_result(s2.docname(:doc1) => {'4'=>@product4})
    s.load_read_state.should == nil
    s2.load_read_state.refresh_time.should == time
    User.is_exist?(params[:attributes][:login]).should == false
    App.load(test_app_name).users.members.should == ["testuser"]
    Source.valid_doctypes.delete(:doc1)
  end
end