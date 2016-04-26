#!/usr/bin/env ruby
$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'installer', 'utils'))

require 'rubygems'
require 'stringio'
require 'fog'
require 'net/http'

require 'constants'
include Constants

BUCKET = 'rhoconnect'

def run_on_server(server, cmds)
  result = server.ssh(cmds)
  result.each do |r|
    raise "Command #{r.command} failed.\nStdout: #{r.stdout}\nStderr: #{r.stderr}" if r.status != 0
    puts "$ #{r.command}"
    puts r.stdout
  end
end

def build_type
  case ARGV[0]
  when 'test'
    'test-packages'
  when 'beta'
    'beta-packages'
  when 'release'
    'packages'
  else
    'packages'
  end
end

# Fills in all necessary information which is stack specific
def compile_stack_info(stack)
  # User is stack specific but not to
  # be included in the fog creation hash
  user = stack[:user]

  local_file = "#{Dir.pwd}/pkg/"
  # Determine what channel to pull the packages from
  channel = build_type

  # Append the rest of the file name according to distribution
  if user == 'ubuntu'
    dist = { :flavor =>        "ubuntu",
              :package =>       "rhoconnect_#{Constants::RC_VERSION}_all.deb",
              :local_file =>    "#{local_file}rhoconnect_#{Constants::RC_VERSION}_all.deb",
              :pkg_mgr =>       'dpkg',
              :pkg_type =>      'DEB',
              :pkg_cmd =>       'apt-get --force-yes -y',
              :deps =>          Constants::DEB_DEPS,
              :repo_src_file => '/etc/apt/sources.list',
              :repo_str =>      '\n' +
                                '# This is the repository for rhoconnect packages\n' +
                                "deb http://#{BUCKET}.s3.amazonaws.com/#{channel}/deb rhoconnect main" }
  elsif user == 'root'
    dist = { :flavor =>        "centos",
              :package =>       "rhoconnect-#{Constants::RC_VERSION}.noarch.rpm",
              :local_file =>    "#{local_file}rhoconnect-#{Constants::RC_VERSION}.noarch.rpm",
              :pkg_mgr =>       'rpm',
              :pkg_type =>      'RPM',
              :pkg_cmd =>       'yum -y',
              :deps =>          Constants::RPM_DEPS,
              :repo_src_file => '/etc/yum.repos.d/rhoconnect.repo',
              :repo_str =>      '[rhoconnect]\n' +
                                'name=Rhoconnect\n' +
                                "baseurl=http://#{BUCKET}.s3.amazonaws.com/#{channel}/rpm" +
                                '\nenabled=1\n' +
                                'gpgcheck=0\n' }
  # else
  #   raise "Incorrect user name"
  end
  [user, dist]
end

def connect_to_amazon
  lines = IO.readlines Constants::ACCESS_KEY_FILE
  access_key        = lines.first.strip.split("=")[1]
  secret_access_key = lines.last.strip.split("=")[1]

  Fog::Compute.new(:provider => 'AWS', :region => Constants::REGION,
    :aws_access_key_id => access_key,
    :aws_secret_access_key => secret_access_key)
end

# Creates a new ec2 instance as per the given stack.
def start_new_instance(connection, params)
  puts "Creating new instance..."

  server = connection.servers.create(params)
  # Wait for machine to be booted
  server.wait_for { ready? }
  # Wait for machine to get an ip-address
  server.wait_for { !public_ip_address.nil? }

  if server.ready?
    # wait for all services to start on remote VM
    puts "Waiting #{Constants::SLEEP} seconds for services to start on remote VM..."
    Constants::SLEEP.times do
      sleep 1
      print "."
      STDOUT.flush
    end
    puts
  else
    raise "Server timed out."
  end
  server
end

def install_package(server, distro_params)
  puts "Preparing sources..."
  run_on_server(server, "sudo touch #{distro_params[:repo_src_file]}") if distro_params[:flavor] == 'centos'
  filename = distro_params[:repo_src_file]
  src_str  = distro_params[:repo_str]

  # Create file for yum rhoconnect sources
  # Get current permissions of file
  perms = server.ssh("stat --format=%a #{filename}")[0].stdout.strip
  # Change permissions so that it can be edited by "others"
  cmds = ["sudo chmod 0666 #{filename}",
          "echo -e \"#{src_str}\" >> #{filename}",
          "sudo chmod 0#{perms} #{filename}"]
  cmds << "sudo #{distro_params[:pkg_cmd]} update" unless distro_params[:flavor] == "centos"
  run_on_server(server, cmds)

  puts "Installing rhoconnect package.\nThis may take a while...\n\n"
  run_on_server(server, "sudo #{distro_params[:pkg_cmd]} install rhoconnect")
end

def start_services(server)
  puts
  ['redis', 'thin', 'nginx'].each do |program|
    status = -1
	  3.times do
	    res = server.ssh("sudo /etc/init.d/#{program} start")
      puts "$ #{res[0].command}"
      puts res[0].stdout
	    status = server.ssh("pgrep -f #{program}")[0].status
	    break status == 0
	    sleep 3
	  end
	  raise "Service #{program} failed to start." if status != 0
	  sleep 10 if program == 'thin'
  end
  puts
end

# Makes an HTTP request to check that the rhoconnect service is working
def check_rhoconnect_status(server)
  host = server.dns_name
  puts "Testing rhoconnect server on host #{host}"
  uri = URI("http://#{host}/console/")

  resp_code = 200
  3.times do |i|
  	response = Net::HTTP.get_response(uri)
  	resp_code = response.code.to_i
  	puts "#{i}: #{response.code} #{response.message}"
  	break if resp_code < 400
  	sleep 10
  end

  if resp_code < 400
    puts "Rhoconnect server up and running!"; puts
  else
    puts "Nginx error log:"
    puts server.ssh('cat /opt/nginx/logs/error.log')[0].stdout
    puts "Thin server logs:"
    puts server.ssh('cat /var/log/thin/thin.0.log')[0].stdout
    puts server.ssh('cat /var/log/thin/thin.1.log')[0].stdout
    raise "Failed to connect to rhoconnect service on #{host}"
  end
end

def ping_remote_host(server)
  status = -1
  10.times do
    begin
      res = server.ssh(['uptime'])
      status = res[0].status
      break if status == 0
    rescue Exception => e
      sleep 6
    end
  end
  status
end

def test_package(connection, stack)
  start_time = Time.now

  user, distro_params = compile_stack_info(stack)
  server = start_new_instance(connection, stack)
  host = server.dns_name
  puts "Remote host #{host} is up and running ..."

  server.username = user
  server.private_key_path = Constants::SSH_KEY
  puts "Establish ssh connection for \"#{user}@#{host}\" ..."
  # For a minute trying to reach remote host
  raise "Cannot establish ssh connection with #{stack[:tags]['Name']} instance." if ping_remote_host(server) != 0
  puts "SSH connection establised!"

  install_package(server, distro_params)
  # Start the redis and nginx servers on the remote machine
  start_services(server)
  # Check the status of the rhoconnect service
  check_rhoconnect_status(server)

  elapsed_time = (Time.now - start_time).to_i
  puts "Test for #{stack[:tags]['Name']} completed in #{elapsed_time/60} min. #{elapsed_time - ((elapsed_time/60)*60)} sec."
  0
rescue => e
  puts e.inspect
  puts e.backtrace
  -1
ensure
  if server
    puts "Terminating #{stack[:tags]['Name']} instance ..."
    server.destroy
  end
end

module ThreadOut
  # Writes to Thread.current[:stdout] instead of STDOUT if the thread local is set.
  def self.write(stuff)
    if Thread.current[:stdout] then
      Thread.current[:stdout].write stuff
    else
      STDOUT.write stuff
    end
  end
end

# Connect to Amamzon EC2 cloud
start_at = Time.now
connection = connect_to_amazon

# Redirect stdout
$stdout = ThreadOut

# Create logs and threads
logs = []
threads = []
STACK_SIZE.times do |i|
  logs  << StringIO.new
  threads << Thread.new(i) do |idx|
    puts "Starting test for #{STACKS[idx][:tags]['Name']} ... "
    Thread.current[:stdout] = logs[idx]
    test_package(connection, STACKS[idx])
  end
end
# Wait till threads re finished
threads.each { |thread| thread.join }

# Output logs and check resluts
threads.each_with_index do |thread, i|
  puts "\n#{STACKS[i][:tags]['Name']} installation log:"
  puts logs[i].string
end
exit_code = 0
threads.each_with_index do |thread, i|
  if thread.value != 0
    puts "Package for #{STACKS[i][:tags]['Name']} failed to pass test!"
    exit_code = -1
  end
end

elapsed_time = (Time.now - start_at).to_i
puts "Elapsed time: #{elapsed_time/60} min. #{elapsed_time - ((elapsed_time/60)*60)} sec."

exit exit_code
