$:.unshift File.join(File.dirname(__FILE__), '..', '..','..','lib')

require 'rubygems'
require 'yaml'

require 'xmlsimple'

module Bench
  module AWSUtils
    extend self
    
    module Constants
      RC_VERSION      = Rhoconnect::VERSION
      REGION          = 'us-west-1'
      TEMPLATE_URL    = 'http://s3.amazonaws.com/rhoconnect-bench/packages/cloud-formation/ec2-autostack.txt'
      CLIENTS_GROUP_LOGICAL_ID = 'BenchClientsGroup'
      WAIT_FOR_SSH = 120
      HOME_DIR        = `echo ~/`.strip.chomp("/")
    end
    
    class ClientsGroup
      attr_accessor :stack_name, :client_instances, :auto_scaling_group
      
      def initialize(stack_name)
        @stack_name = stack_name
        auto_scaling = Fog::AWS::AutoScaling.new(
          :region => Bench::AWSUtils.aws_region,
          :aws_access_key_id     => Bench::AWSUtils.aws_access_key_id,
          :aws_secret_access_key => Bench::AWSUtils.aws_secret_access_key
        )
        group_resources = Bench::AWSUtils.cloud_formation.describe_stack_resources({'StackName' => stack_name, 
          'LogicalResourceId' => Bench::AWSUtils::Constants::CLIENTS_GROUP_LOGICAL_ID}).body

        @auto_scaling_group = auto_scaling.groups.get(group_resources['StackResources'].first['PhysicalResourceId'])      
        @client_instances = []
        @auto_scaling_group.instances.each do |instance|
          next if instance.auto_scaling_group_name != @auto_scaling_group.id
          ec2_instance = Bench::AWSUtils.fog_connection.servers.get(instance.id)
          @client_instances << ec2_instance.dns_name 
        end
      end
    end
    
    class << self
      attr_accessor :fog_connection, :cloud_formation, :aws_access_key_id, :aws_secret_access_key, :aws_region
      attr_accessor :aws_key_pair_name, :aws_ssh_pem_file
    end
    
    def validate_presense_of_file(fname)
      return File.file?(File.expand_path(fname.to_s))
    end

    def init_connection(settings_file)
      unless Bench::gem_installed?('net-ssh-multi')
        puts "In order to run distributed benchmark you need to have 'net-ssh-multi' gem installed"
        puts "Install it by using : '[sudo] gem install net-ssh-multi'"
        raise "Gem 'net-ssh-multi' is missing"    
      end
      unless Bench::gem_installed?('fog')
        puts "In order to run distributed benchmark you need to have 'fog' gem installed"
        puts "Install it by using : '[sudo] gem install fog'"
        raise "Gem 'fog' is missing"                
      end
      
      require 'net/ssh/multi'
      require 'fog'
      
      fog_conf_file = ENV['HOME'] + '/.fog'
      settings_file ||= fog_conf_file
      
      if validate_presense_of_file(settings_file)
        # Read Fog ~/.fog configuration file
        # :default:
        #   :aws_access_key_id:     AKIAI...
        #   :aws_secret_access_key: 9l2ruLeCINbilik...
        #   :region:                us-west-1
        puts "Using AWS settings from #{settings_file} file" 

        settings = YAML::load(File.open(settings_file))
        if not settings or settings[:default].nil?
          raise "ERROR : AWS Settings file '#{settings_file}' doesn't have the mandatoty 'default' section"
        end
        config = settings[:default]
        
        @aws_ssh_pem_file = config[:aws_ssh_pem_file]
        unless validate_presense_of_file(aws_ssh_pem_file)
          raise "ERROR : Can not locate SSH Access Pem File '#{aws_ssh_pem_file}'\nMake sure you set :aws_ssh_pem_file properly in the AWS Settings file"
        end
        @aws_access_key_id = config[:aws_access_key_id]
        @aws_secret_access_key = config[:aws_secret_access_key]
        @aws_region = config[:region] || Constants::REGION
        @aws_key_pair_name = config[:aws_key_pair_name]
          
      else
        raise "ERROR : Can not locate AWS Settings file '#{settings_file}'\nYou must have this file in order to run the Distributed Benchmark Test"
      end
      
      make_fog
      make_cloud_formation
    end
    
    # get_access_keys
    # Retrieves the access key and secret access key from the above specified file.
    def get_access_keys(fname)
      return true if aws_access_key_id and aws_secret_access_key
            
      lines = IO.readlines(fname)
      @aws_access_key_id = lines.first.strip.split("=")[1]
      @aws_secret_access_key = lines.last.strip.split("=")[1]
    end

    # make_fog
    # Generates the Fog object used to create the new ec2 instance.
    def make_fog
      @fog_connection ||= Fog::Compute.new(
          :provider              => 'AWS',
          :region                => aws_region,
          :aws_access_key_id     => aws_access_key_id,
          :aws_secret_access_key => aws_secret_access_key
      )
    end #make_fog

    def make_cloud_formation
      @cloud_formation ||= Fog::AWS::CloudFormation.new(
        :region => aws_region,
        :aws_access_key_id     => aws_access_key_id,
        :aws_secret_access_key => aws_secret_access_key
      )
    end
    
    def get_template_data(template_url)
      template_data = ''
      begin
        uri = URI.parse(template_url)
        unless uri.scheme
          File.open(uri.path) { |f| template_data << f.read }
        else
          response = Net::HTTP.get_response(uri) 
          template_data = response.body if response.code == '200'
        end      
      rescue Exception => e
        puts "ERROR: Can not obtain CloudFormation template from '#{template_url}'"
        puts e.message
      end
      template_data
    end
    
    # Creates new CloudFormation stack based upon template
    def create_cf_stack
      puts ""
      puts " Creating new AWS CloudFormation stack at '#{aws_region}' region"
      puts " using '#{Constants::TEMPLATE_URL}' template ..."
      puts "    This may take several minutes, please be patient ..."
      puts ""

      stack_name = nil
      stack_created = false
      
      begin
        template_data = get_template_data(Constants::TEMPLATE_URL)
        cloud_formation.validate_template('TemplateBody' => template_data)
       
        template_params = {}
        template_params['SecurityKeyPair'] = aws_key_pair_name.to_s
        options = {'TemplateBody' => template_data,
                    'Parameters' => template_params}
        stack_name = "BenchStack" + Time.now.strftime("%Y%m%d%H%M%S")
        result = cloud_formation.create_stack(stack_name, options)
        
        event_counter = 0
        in_progress = true
        stack_created = false
        while in_progress
          events = cloud_formation.describe_stack_events(stack_name).body['StackEvents']
          events.reverse[event_counter..-1].each do |event|
            puts "Timestamp: #{event['Timestamp']}"
            puts "LogicalResourceId: #{event['LogicalResourceId']}"
            puts "ResourceType: #{event['ResourceType']}"
            puts "ResourceStatus: #{event['ResourceStatus']}"
            puts "ResourceStatusReason: #{event['ResourceStatusReason']}" if event['ResourceStatusReason']
            puts "--"
          
            # track creation of the stack
            if event['LogicalResourceId'] == stack_name
              case event['ResourceStatus']
              when 'CREATE_COMPLETE'
                stack_created = true
                in_progress = false
              when /ROLLBACK/
                stack_created = false
                in_progress = false
              when /DELETE/
                stack_created = false
                in_progress = false
              when /FAILED/
                stack_created = false
                in_progress = false
                break
              end
            end
          end
          event_counter += events.size - event_counter
          sleep(2)
        end
      rescue Excon::Errors::BadRequest => excon_error
        error_str = XmlSimple.xml_in(excon_error.response.body)['Error'][0]['Message'][0]
        puts "ERROR: Cannot create AWS CloudFormation stack  : #{error_str}"
        stack_created = false
      rescue Excon::Errors::Forbidden => excon_error
        error_str = XmlSimple.xml_in(excon_error.response.body)['Error'][0]['Message'][0]
        puts "ERROR: Cannot create AWS CloudFormation stack  : #{error_str}"
        stack_created = false
      rescue Exception => e
        puts "ERROR: Cannot create AWS CloudFormation stack  : #{e.class.name}: #{e.message}"
        stack_created = false
      end
      
      clients_group = nil
      if stack_created
        clients_group = get_clients_group(stack_name)
         # wait until the SSH service is up and running
        stack_created = establish_ssh_connection(clients_group)
      end
      
      unless stack_created
        delete_cf_stack(stack_name)
        clients_group = nil
        stack_name = nil
      end
      
      clients_group
    end
    
    # Creates new CloudFormation stack based upon template
    def delete_cf_stack(stack_name)
      return unless stack_name
      puts ""
      puts "Destroying AWS CloudFormation stack '#{stack_name}' at '#{ aws_region}' region"
      puts " NOTE: this command doesn't ensure deletion of the stack. "
      puts "       It is advised to check later that the stack has been really destroyed"
      puts ""
      
      begin
        cloud_formation.delete_stack(stack_name)
      rescue Excon::Errors::BadRequest => excon_error
        error_str = XmlSimple.xml_in(excon_error.response.body)['Error'][0]['Message'][0]
        puts "ERROR: Cannot delete the stack '#{stack_name}' : #{error_str}"
      rescue Excon::Errors::Forbidden => excon_error
        error_str = XmlSimple.xml_in(excon_error.response.body)['Error'][0]['Message'][0]
        puts "ERROR: Cannot delete the stack '#{stack_name}' : #{error_str}"
      rescue Exception => e
        puts "ERROR: Cannot delete the stack '#{stack_name}' : #{e.class.name}: #{e.message}"
      end
    end
    
    def get_clients_group(stack_name)
      ClientsGroup.new(stack_name)
    end
    
    def establish_ssh_connection(clients_group)
      STDOUT.sync = true
      ssh_established = false
      begin 
        start_timestamp = Time.now
        sess_options = {:keys => [aws_ssh_pem_file]}
        # just some simple command
        command = 'pwd 1>/dev/null'
        
        # clean-up outdated info (sometimes DNS names are re-used
        # so we need to clean-up SSH known hosts file)
        clients_group.client_instances.each do |hostname|
          system("ssh-keygen -R #{hostname} 1>/dev/null 2>&1")
        end
          
        puts ""
        puts " Stack '#{clients_group.stack_name}' is created. Waiting for SSH services to start-up..."
        while not ssh_established
          begin
            run_stack_ssh_command(clients_group.client_instances, command)
            # if we are here - SSH command has executed succesfully
            puts " Done."
            ssh_established = true
            break
          rescue Interrupt => i
            raise "User Interruption"
          rescue Net::SSH::AuthenticationFailed => e
            raise e
          rescue OpenSSL::PKey::PKeyError => e
            raise e
          rescue Errno::ECONNREFUSED => e
            # service is not yet started - wait more
          end
        
          # try for 60 seconds maximum
          if (Time.now.to_i - start_timestamp.to_i) > Constants::WAIT_FOR_SSH
            puts " Failed!"
            puts "ERROR: Cannot establish SSH session with the stack's EC2 instances..."
            puts ""
            break
          end
          
          sleep(10)
          print '. '
        end
      rescue Exception => e
        puts " Failed!"
        puts "ERROR: Cannot establish SSH session with the stack's EC2 instances : #{e.class.name} : #{e.message}"
        puts ""
      end
      
      ssh_established
    end
    
    def run_stack_ssh_command(ec2_clients, command)
      sess_options = {:keys => [aws_ssh_pem_file]}
      Net::SSH::Multi.start({:default_user => 'ec2-user'}) do |session|
        # define the servers we want to use
        session.use(sess_options) { ec2_clients }

        # execute commands on all servers
        session.exec command
      end
    end
  end
end
