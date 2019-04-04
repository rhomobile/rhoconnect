require 'rhoconnect/middleware/cors'
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

describe "CORS middleware" do

  class StubApp
    def call(env)
      [200, {'Set-Cookie' => 'someCookie=someValue', 'Content-Length' => '0'}, '']
    end
  end

  before(:each) do
    @app = StubApp.new

    @middleware = Rack::Cors.new @app, {} do |cfg|
        cfg.allow do |allow|
          allow.origins /allowed_origin/, 'file://'
          allow.resource "/StubAdapter", :headers => 'allowed_header', :methods => [:get, :post, :put, :delete], :credentials => true, :expose => 'Content-Length'
          allow.resource "/StubAdapter/any_header_allowed_here", :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
          allow.resource "/StubAdapter/no_default_exposed_headers", :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
        end
    end
  end

  it "preflight check should allow unknown origins if public access is configured" do
    mv = Rack::Cors.new @app, {} do |cfg|
        cfg.allow do |allow|
          allow.origins '*', 'mock_value'
          allow.resource '/mock+path',   :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
          allow.resource '/mock%20path',   :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
          allow.resource /\/mock_path/,   :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true

          exception_happens = false
          begin
            allow.resource nil,   :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
          rescue Exception => e
            exception_happens = true
            expect(e.is_a?(TypeError)).to be true
          end
          expect(exception_happens).to be true

          allow.resource "/*", :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
        end
    end

    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'wrong_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = mv.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Allow-Origin']).to eq('*')
  end

  it "preflight check should disable unknown origins" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'wrong_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Allow-Origin']).not_to eq('wrong_origin')
  end

  it "preflight check should allow known origins" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Allow-Origin']).to eq('allowed_origin')
  end

  it "able to use fallback X-ORIGIN request header if ORIGIN header is undefined" do
    env = {
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_X_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Allow-Origin']).to eq('allowed_origin')
  end

  it "preflight check treats empty 'null' origin as 'file://' one" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'null',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Allow-Origin']).to eq('file://')
  end

  it "preflight check should enable allowed request headers" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
        'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'allowed_header'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    #headers['Access-Control-Allow-Origin'].should == 'allowed_origin'
    expect(headers['Access-Control-Allow-Headers']).to eq('allowed_header')
  end

  it "preflight check should disable not allowed request headers" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
        'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'not_allowed_header'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    #headers['Access-Control-Allow-Origin'].should == 'allowed_origin'
    expect(headers['Access-Control-Allow-Headers']).not_to eq('not_allowed_header')
  end

  it "preflight check should allow any request headers if configured so" do
    env = {
        'REQUEST_METHOD' => 'OPTIONS',
        'PATH_INFO' => '/StubAdapter/any_header_allowed_here',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
        'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'not_allowed_header'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    #headers['Access-Control-Allow-Origin'].should == 'allowed_origin'
    expect(headers['Access-Control-Allow-Headers']).to eq('not_allowed_header')
  end


  it "only allowed response headers should be exposed" do
    env = {
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/StubAdapter',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Expose-Headers']).to eq('Content-Length')
  end

  it "no response headers should be exposed by default" do
    env = {
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/StubAdapter/no_default_exposed_headers',
        'HTTP_ORIGIN' => 'allowed_origin',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
    }
    status, headers, body = @middleware.call(env)
    expect(200).to eq(status)
    expect(headers['Access-Control-Expose-Headers']).to eq('')
  end


=begin
  it "should skip if it isn't a sync protocol URI, for old REST routes" do
    env = {
        'PATH_INFO' => WRONG_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware_old_routes.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    COOKIE_NV.should_not == env['HTTP_COOKIE']
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should_not == body
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
    headers['Content-Length'].should == body.length.to_s
    ''.should_not == body
  end
=end
end
