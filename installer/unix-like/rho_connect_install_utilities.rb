require 'net/http'
require 'net/https'
require 'rho_connect_install_constants'
require 'rho_connect_install_installers'
require 'rho_connect_install_checkers'
require 'rho_connect_install_dnd'

include Installers
include Checkers
include DownloadAndDocompress

module Utilities
  # log_print
  # This method displays, in minutes, how long the installation process took
  def log_print(string)
    puts string
    @log.info {string}  unless @log == nil
  end #log_print

  private
  
  # cmd
  # This method issues the given system command and calls log_print for output
  def cmd(cmd)
    @log.info cmd unless @log == nil
    res = `#{cmd} 2>&1`
    @log.info res unless @log == nil
    $?
  end #cmd

  #set_log_file
  def set_log_file(log)
    @log = log
  end #set_log_file 
  
  def print_header(string)
    log_print string
  end #print_header
  
  # cleanup
  # This method moves all compressed files from the installation directory
  # that were downloaded by this installation process
  def cleanup(prefix)
    print_header "Cleaning up ..."
    Constants::SOFTWARE.each do |sw|
      cmd "rm #{prefix}/#{sw}.tar.gz; rm -rf #{prefix}/#{sw}" if File.exist? "#{prefix}/#{sw}.tar.gz"
    end
  end #cleanup

end #Utilities
