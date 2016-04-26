require 'sinatra/base'
require 'erb'
require 'json'
require 'rhoconnect/graph_helper'

module RhoconnectConsole
  class << self
    ROOT_DIR = File.dirname(File.expand_path(__FILE__)) unless defined? ROOT_DIR
    def root_path(*args)
      File.join(ROOT_DIR, *args)
    end
  end

  class Server < Sinatra::Base
    set :views,   RhoconnectConsole.root_path('templates')
    set :public_folder, RhoconnectConsole.root_path
    set :static,        true
    use Rack::Session::Cookie, :key => 'rhoconnect.console',
      :secret => SecureRandom.hex(64)
    HEROKU_NAV = ENV['INSTANCE_ID'] ? RestClient.get('http://nav.heroku.com/v1/providers/header') : nil
    before do
      headers['Expires'] = 'Sun, 19 Nov 1978 05:00:00 GMT'
      headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
      headers['Pragma'] = 'no-cache'
    end
    include GraphHelper

    get '/' do
      #if heroku instance single sign will already have logged in a have token in session
      @token = session[:token] if ENV['INSTANCE_ID']
      @heroku = RestClient.get('http://nav.heroku.com/v1/providers/header') if @token
      @version = Rhoconnect::VERSION
      @domain =  "#{request.scheme}://#{request.host_with_port}"
      erb :index
    end

    get "/heroku/resources/:id" do
      begin
        # check heroku addon started app
        halt 403 unless ENV['INSTANCE_ID'] == params[:id]  && params[:token] == ENV['API_TOKEN']
        # rhoconnect authentication
        session[:login] = 'rhoadmin'
        session[:token] = User.load(session[:login]).token.value
      rescue Exception => e
        session[:token] = nil
        halt 403
      end
      response.set_cookie('heroku-nav-data', :value => params[:nav], :path => '/')
      redirect '/'
    end

    post "/get_user_graph" do
      count_graph('timing/usercount', "User Count", "Users", "users")
    end

    post '/source_timing' do
      source_timing(params)
    end

    post '/http_timing' do
      http_timing(params)
    end

    post '/http_timing_key' do
      http_timing_key(params)
    end

    post '/device_count' do
      count_graph('timing/devicecount', "Device Count", "Devices", "clients")
    end

    get '/get_sources' do
      sources = App.load(APP_NAME).sources
      sources.to_json
    end

    get '/get_http_routes' do
      # keys = get_user_count("http:*:*")
      #   sources = get_sources('all')
      #
      #   #loop through arrays and remove any regex matches
      #   keysf = keys.inject([]) do |keys_final, element|
      #     found = true
      #     sources.each do |s|
      #       found = false if element.match(s)
      #     end
      #     keys_final << element.strip if found
      #     keys_final
      #   end

      keysf = get_http_routes()

      keysf.to_json
    end

  end
end