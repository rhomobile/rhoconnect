require 'rho_connect_install_utilities'
require 'rho_connect_install_constants'

include Utilities
include Constants

class Yum
  attr_accessor :options
  
  def initialize(options)
    @@flavor = "Yum"
    @options = options
  end #initialize

  # check_for_installed_software_only
  # This method runs checks against the software that must be installed.
  def check_for_installed_software_only
    check_all_installed @options
  end #check_for_installed_software_only

  # execute_installation
  # This method orchestrates the actual installation process
  def execute_installation
    #start logging
    set_log_file @options[:log]

    download_and_decompress(@options[:prefix], [REDIS_URL, SQLITE3_URL, NGINX_URL])

    install_redis if @options[:redis]
    install_sqlite # Cent OS 5.x uses obsolete sqlite3 libs, update them the latest ones
    configure_nginx @options

    install_all_gems
    install_rhoconnect

    #remove downloaded tarballs
    cleanup options[:prefix]
  end #execute_installation 
 
  # to_s
  # This method overrides the default to_s method
  def to_s
    string = "Debian Installation Parameters:\n"
    string << "\tPackage Manager\n"
    string << "\t\tapt-get\n"
    Constants::DEFAULTS.each do |key, val|
      string << "\t" + key + "\n"
      val.each do |field|
        string << "\t\t" + field + "\n"
      end #do
    end #do
    
    string
  end #to_s
    
end #Yum
