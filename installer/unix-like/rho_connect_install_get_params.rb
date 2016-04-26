require 'rho_connect_install_constants'
require 'rho_connect_install_debian'
require 'rho_connect_install_yum'

module GetParams
  # get_flavor
  # determine whether running on a debian system or a yum system
  def get_flavor(options)
  get_cmd = ''
    Constants::SUPPORTED_PKG_MGRS.each do |mgr|
      if `which #{ mgr } 2> /dev/null` != ""
        get_cmd = mgr
      end #if
    end #do
    
    case get_cmd
    when 'apt-get'
      flavor = Debian.new(options)
    when 'yum'
      flavor = Yum.new(options)
    else
      log_print "Supported package manager not found"
      exit(3)
    end #case    
    
    flavor
  end #get_flavor
end #GetParams
