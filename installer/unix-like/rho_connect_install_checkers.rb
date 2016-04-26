require 'rho_connect_install_constants'

module Checkers
  # check_all_installed
  # This method runs all tests that check whether or not the software is
  # installed correctly.
  def check_all_installed(options)
    @options=options
    not_installed = ""
    Constants::CHECKS.each do |check|
      installed = self.send(check)
      if installed && !installed.empty?
        not_installed << installed
      end #if
    end #do
    if not_installed && !not_installed.empty?
      log_print "The following packages are not installed properly"
      log_print not_installed
    else
      log_print "Everything is fully installed"
    end #if
  end #check_all_installed
  
  # check_all_packages
  # This method calls check_package for each package in the list defined in the 
  # Constants file
  def check_all_packages
    packages_not_installed = []
    Constants::PACKAGES.each do |pkg|
      string = "Looking for package #{pkg}..."
      installed = check_package(pkg)
      installed ? string << green("Found") : string << red("Not Found")
      log_print string
      if !installed
        #if not installed append package name to packages_not_installed list
        packages_not_installed << pkg
      end #if
    end #do
    
    packages_not_installed
  end #check_all_packages

  # check_package
  # This method uses a system call to check that an individual package is
  # installed
  def check_package(pkg)
    string = "Looking for #{pkg}..."
    installed = `#{ @options[:pkg_chkr] } | grep #{ pkg }`
    if installed !~ /.*#{ pkg }.*/
      installed = false
    else
      installed = true
    end #if
  
    installed
  end #check_package
  
  # check_all_gems
  # This method calls check_gem for each gem in the list of gems defined in the
  # Constants file
  def check_all_gems(gem_path)
    gems_not_installed = []
    Constants::GEMS.each do |gem|
      string = "Looking for Gem \"#{gem}\"..."
      installed = check_gem gem, gem_path
      installed ? string << green("Found") : string << red("Not Found")
      log_print string
      if !installed
        #if not installed append gem name to gems_not_installed list
        gems_not_installed << gem
      end #if
    end # do
    
    gems_not_installed
  end #check_all_gems

  # check_gem
  # This method uses a system call to chack that a gem is installed
  def check_gem(gem, gem_path)
    result = `#{gem_path} query --local | grep #{ gem }`
    if result  == ""
      installed = false
    else
      installed = true
    end #if
    
    installed
  end #check_gem
  
  # check_web_server_running
  # This method checks the response from the WEB_SERVER_URL defined in the
  # Constants file to make sure the web server is up and running
  def check_web_server_running
    string = "Testing Web Server..."
    url = Constants::WEB_SERVER_URL

    # check if http:// was in the url if not add it in there
    url.insert(0, "http://")  unless(url.match(/^http\:\/\//))

    # Get the HTTP_RESPONSE from the site we are checking
    begin
      res = Net::HTTP.get_response(URI.parse(url.to_s))
      running = false
      # Check the response code
      if !res.code =~ /2|3\d{2}/
        string << " " + red("Not Running!")
      else
        running = true
        string << " " + green("Running")
      end #if
      log_print string
    rescue
      @log.error {"#{@options[:web_server]} web server unresponsive!"}
    end

    running
  end #check_web_server_running
  
  # colorize
  # Inserts color code into text strings for colorized output
  def colorize(text, color_code)
    "#{color_code}#{text}\033[0m"
  end
  
  # red
  # Changes text to a red color
  def red(text)
    colorize text, "\033[1;31m"
  end
  
  # green
  # Changes text to a green color
  def green(text)
    colorize text, "\033[1;32m"
  end
end #Checkers
