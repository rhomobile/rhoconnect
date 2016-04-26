require 'rest_client'
require 'zip'
require 'securerandom'
$:.unshift File.dirname(__FILE__)
require 'bench/timer'
require 'bench/logging'
require 'bench/utils'
require 'bench/bench_result_processor'
require 'bench/result'
require 'bench/session'
require 'bench/runner'
require 'bench/statistics'
require 'bench/cli'
require 'bench/test_data'
$:.unshift File.join(File.dirname(__FILE__),'..')
require 'scripts/helpers'

$:.unshift File.join(File.dirname(__FILE__),'..','..','..','lib')
require 'rhoconnect'

# Inspired by Trample: http://github.com/jamesgolick/trample

module Bench
  class << self
    include Logging
    include TestData
    include Utils

    attr_accessor :concurrency, :iterations, :admin_login, :simtime, :adapter_name
    attr_accessor :admin_password, :user_name
    attr_accessor :password, :base_url, :host, :token
    attr_accessor :total_time, :sessions, :verify_error
    attr_accessor :adapter_name, :datasize, :result_filename
    attr_accessor :main_marker, :start_time, :end_time

    # these attributes for distributed testing
    attr_accessor :processor_id, :save_to_redis, :sync_key

    def config
      begin
        @verify_error ||= 0
        yield self
      rescue Exception => e
        puts "error in config: #{e.inspect}"
        raise e
      end
    end

    def synchronize
      begin
        yield self
      rescue Exception => e
        puts "error in synchronize: #{e.inspect}"
        raise e
      end
    end

    def get_server_state(doc)
      token = get_token
      @body = RestClient.get(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/store/#{doc}",
        {'X-RhoConnect-API-TOKEN' => token})
      JSON.parse(@body.to_s)
    end

    def get_server_value(doc)
      token = get_token
      @body = RestClient.get(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/store/#{doc}",
        {'X-RhoConnect-API-TOKEN' => token, :content_type => :json})
    end

    def reset_app
      RestClient.post(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/system/reset",
        {},
        {:content_type => :json, 'X-RhoConnect-API-TOKEN' => get_token})
    end

    def create_user(user_name, password)
      token = get_token
      RestClient.post(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/users",
        {:app_name => @app_name, :attributes => {:login => user_name, :password => password}}.to_json,
        {:content_type => :json, 'X-RhoConnect-API-TOKEN' => token})
    end

    def delete_user(user_name)
      token = get_token
      RestClient.delete("#{@host}/rc/v1/users/#{user_name}",
        { 'X-RhoConnect-API-TOKEN' => token } )
    end

    def set_server_state(doc,data,append=false)
      token = get_token
      params = {:data => data, :append => append}
      params[:data_type] = 'string' if data.is_a? String
      RestClient.post(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/store/#{doc}",
        params.to_json,
        {'X-RhoConnect-API-TOKEN' => token, :content_type => :json})
    end

    def reset_refresh_time(source_name,poll_interval=nil)
      token = get_token
      RestClient.put(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/readstate/users/#{@user_name}/sources/#{source_name}",
        {:poll_interval => poll_interval}.to_json,
        {'X-RhoConnect-API-TOKEN' => token, :content_type => :json})
    end

    def set_simulate_time(source_name,simulate_time=0)
      token = get_token
      RestClient.put(
        "#{@host}/rc/#{Rhoconnect::API_VERSION}/sources/#{source_name}",
        {:data => {:simulate_time => simulate_time}}.to_json,
        {'X-RhoConnect-API-TOKEN' => token, :content_type => :json})
    end

    def get_token
      unless @token
        @token = RestClient.post(
          "#{@host}/rc/#{Rhoconnect::API_VERSION}/system/login",
          {:login => @admin_login, :password => @admin_password}.to_json,
          :content_type => :json)
      end
      @token
    end

    def get_test_server(app_name = nil)
      if @base_url.nil?
        app_name = 'benchapp' unless app_name
        settings = load_settings(File.join(File.dirname(__FILE__),'..',app_name,'settings','settings.yml'))
        @base_url = settings[:development][:syncserver].gsub(/\/$/,'')
      end
      uri = URI.parse(@base_url)
      port = (uri.port and uri.port != 80) ? ":"+uri.port.to_s : ""
      if not uri.scheme
        raise "URI '#{@base_url}' is invalid:\n\t- doesn't have the required scheme part (for example , http://)"
      end
      @host = "#{uri.scheme}://#{uri.host}#{port}"
      puts "Test server is #{@host}..."
    end

    def test(&block)
      Runner.new.test(@concurrency,@iterations,&block)
    end

    def verify(&block)
      yield self,@sessions
    end

    # TODO: These functions are duplicates!

    def compress(path)
      path.sub!(%r[/$],'')
      archive = File.join(path,File.basename(path))+'.zip'
      FileUtils.rm archive, :force=>true
      Zip::File.open(archive, 'w') do |zipfile|
        Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
          zipfile.add(file.sub(path+'/',''),file)
        end
      end
      archive
    end
  end
end