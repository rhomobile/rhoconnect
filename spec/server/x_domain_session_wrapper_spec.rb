require 'rhoconnect/middleware/x_domain_session_wrapper'
require File.join(File.dirname(__FILE__),'..','spec_helper')

require "cgi"

COOKIE_NAME = 'some_cookie'
COOKIE_VALUE = 'some_session_key=some_session_value'

COOKIE_NV = "#{COOKIE_NAME}=#{COOKIE_VALUE}"
COOKIE_ANOTHER_NV = "#{COOKIE_NAME}=#{COOKIE_VALUE}_another"

PROPER_QUERY_STRING = "?abc=123&#{COOKIE_NAME}=#{CGI.escape(COOKIE_VALUE)}&de=45"
WRONG_QUERY_STRING = "?abc=123&#{COOKIE_NAME}_wrong=#{CGI.escape(COOKIE_VALUE)}&de=45"

PROPER_URI_NEW = '/api/application'
PROPER_URI_OLD = '/application'
WRONG_URI = '/some/wrong/path/to/rhoconnect/application'

LOGIN_URI_NEW = '/api/application/clientlogin'
LOGIN_URI_OLD = '/application/clientlogin'

describe "XDomainSessionWrapper middleware" do

  class StubApp
    def call(env)
      [200, {'Set-Cookie' => COOKIE_ANOTHER_NV, 'Content-Length' => '0'}, ['']]
    end
  end

  before(:each) do
    app ||= StubApp.new

    @middleware_new_routes = Rhoconnect::Middleware::XDomainSessionWrapper.new(app, {
        :session_cookie => COOKIE_NAME,
        :api_uri_regexp => /\A\/api\/application/,
        :login_uri_regexp => /\A\/api\/application\/clientlogin/
    })

    @middleware_old_routes = Rhoconnect::Middleware::XDomainSessionWrapper.new(app, {
        :session_cookie => COOKIE_NAME,
        :api_uri_regexp => /\A\/application/,
        :login_uri_regexp => /\A\/application\/clientlogin/
    })

  end

  it "should skip if it isn't a sync protocol URI, for new REST routes" do
    env = {
        'PATH_INFO' => WRONG_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_new_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    COOKIE_NV.should_not == env['HTTP_COOKIE']
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "should skip if it isn't a sync protocol URI, for old REST routes" do
    env = {
        'PATH_INFO' => WRONG_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_old_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    COOKIE_NV.should_not == env['HTTP_COOKIE']
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "should process cookie from QUERY_STRING if it is a sync protocol URI, for new REST routes" do
    env = {
        'PATH_INFO' => PROPER_URI_NEW,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_new_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "should process cookie from QUERY_STRING if it is a sync protocol URI, for old REST routes" do
    env = {
        'PATH_INFO' => PROPER_URI_OLD,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_old_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "shouldn't process cookie from QUERY_STRING if there is no appropriate parameter name or value, for new REST routes" do
    env = {
        'PATH_INFO' => PROPER_URI_NEW,
        'QUERY_STRING' => WRONG_QUERY_STRING
    }
    status, headers, body = @middleware_new_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should_not == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "shouldn't process cookie from QUERY_STRING if there is no appropriate parameter name or value, for old REST routes" do
    env = {
        'PATH_INFO' => PROPER_URI_OLD,
        'QUERY_STRING' => WRONG_QUERY_STRING
    }
    status, headers, body = @middleware_old_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should_not == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should == body[0]
  end

  it "should respond with cookie in a body if it is a login URI, for new REST routes" do
    env = {
        'PATH_INFO' => LOGIN_URI_NEW,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_new_routes.call(env)
    200.should == status
    headers['Set-Cookie'].should == COOKIE_ANOTHER_NV
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should_not == body[0]
  end

  it "should respond with cookie in a body if it is a login URI, for old REST routes" do
    env = {
        'PATH_INFO' => LOGIN_URI_OLD,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_old_routes.call(env)
    200.should == status
    headers['Set-Cookie'].should == COOKIE_ANOTHER_NV
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body[0].length.to_s
    ''.should_not == body[0]
  end
end
