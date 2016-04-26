require "cgi"
require 'rhoconnect/middleware/helpers'

module Rhoconnect
  module Middleware
    class XDomainSessionWrapper
      def initialize(app, opts={})
        @app = app
        @session_cookie = opts[:session_cookie] || 'rhoconnect_session'
        @api_uri_regexp = opts[:api_uri_regexp] || /\A\/api\/application/
        @login_uri_regexp = opts[:login_uri_regexp] || /\A\/api\/application\/clientlogin/
        yield self if block_given?
      end

      def is_sync_protocol(env)
        # if it is rhoconnect protocol URI
        @api_uri_regexp.match(env['PATH_INFO'])
      end

      def call(env)
        if is_sync_protocol(env)
          env['HTTP_COOKIE'] = env['HTTP_COOKIE'] || CGI.unescape(get_session_from_url(env))
        end
        #puts "and here #{@app.inspect} #{env.inspect}"
        status, headers, body = @app.call(env)

        if is_sync_protocol(env)
          cookies = headers['Set-Cookie'].to_s
          #puts "<----- Cookies: #{cookies}"
          # put cookies to body as JSON on login success
          if @login_uri_regexp.match(env['PATH_INFO']) && status == 200
            body = session_json_from(cookies)
            headers['Content-Length'] = body.length.to_s
          end
        end

        # The Body itself should not be an instance of String,as this will break in Ruby 1.9
        body = ["#{body}"] if body.is_a?(String)
        [status, headers, body]
      end

      def session_json_from(cookies)
        rexp = Regexp.new(@session_cookie +'=[^\s]*')
        sc = cookies.to_s.slice rexp
        "{\"" +@session_cookie +"\": \"#{CGI.escape sc.to_s}\"}"
      end

      def get_session_from_url(env)
        rexp = Regexp.new(@session_cookie +'=.*\Z')
        qs = env['QUERY_STRING'].to_s.slice rexp
        qs = qs.to_s.split(/&/)[0]
        nv = qs.to_s.split(/=/)
        return nv[1] if nv.length > 1
        ''
      end
    end
  end
end