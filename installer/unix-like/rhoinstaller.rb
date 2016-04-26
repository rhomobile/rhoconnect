$:.unshift File.expand_path(File.dirname(__FILE__))

require 'optparse'
require 'logger'
require 'time'
require 'rho_connect_install_get_params'
require 'rho_connect_install_constants'
require 'rho_connect_install_utilities'

include GetParams
include Utilities

# Simplify logger output format: [timestamp] message
class Logger
  class Formatter
    #Format = "[%s] %s\n"
    def call(severity, time, progname, msg)
      "[%s] %s\n" % [format_datetime(time), msg]
    end
  end
end

#make sure script is only run by root users
user = `whoami`.strip
if user != "root"
  puts "This installation must be performed by the root user"
  exit(2)
end
 
options = {}

optparse = OptionParser.new do|opts|
  options[:redis] = true
  opts.on( '--no-redis', '', 'Skip installing the redis server.') do
    options[:redis] = false
  end #do

  options[:offline] = false
  opts.on( '-o', '--offline', 'Check that all necessary files are installed in /opt/rhoconnect if no prefix is specified.' ) do
    options[:offline] = true
  end #do
  
  options[:prefix] = Constants::DEFAULT_INSTALL_DIR
  opts.on( '-p', '--prefix PREFIX', 'Specify PREFIX as the installation directory.  Defalut is /opt/rhoconnect.' ) do |file|
    options[:prefix] = file
  end #do

  options[:ruby_version] = "rubyee"
  opts.on( '-r', '--ruby-version VERSION', 'Specify version of ruby to be installed.  Default is Ruby Enterprise.' ) do |ver|
    options[:ruby_version] = ver
  end #do

  options[:silent] = false
  opts.on( '-s', '--silent', 'Perform installation with minimal output' ) do
    options[:silent] = true
  end #do

  options[:web_server] = "nginx"
  opts.on( '-w', '--web-server SERVER', 'Specify apache2 or nginx.  Default is Nginx.' ) do |server|
    options[:web_server] = server
  end #do

  opts.on( '-d', '--dist DISTRO', 'Specify DISTRO as the current distribution.' ) do |dist|
    options[:dist] = dist
  end
  opts.on('-l', '--Logfile file', ' Specify installtion log file') do |file|
    options[:log_file] = file
  end
  
  opts.on( '-h', '--help', 'Display this screen.' ) do
    puts opts
    exit
  end #do
end
 
optparse.parse!

@log_file = options[:log_file]
log = Logger.new(@log_file)
log.datetime_format = "%Y-%m-%d %H:%M:%S"  # simplify time output
options[:log] = log

#downcase all options hash string values
options.each do |key, val|
  options[key] = val.downcase if val.class == String
end

#Start installation process
#determine into what directory things will be installed
rho = GetParams.get_flavor(options)

if options[:offline]
  rho.check_for_installed_software_only
else
  begin
    rho.execute_installation
  rescue => ex
    log.error "#{ex.message}"
    puts
    puts "#{ex.message}"
    exit(1)
  end
end
