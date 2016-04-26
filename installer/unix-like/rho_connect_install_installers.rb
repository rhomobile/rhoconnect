#require 'tempfile'
require 'rho_connect_install_constants'
require 'rho_connect_install_checkers'

include Checkers
include Constants

module Installers
  def configure_nginx(options)
    raise "Please stop the web server and then reinstall the package." if check_web_server_running
    @options=options
    if @options[:web_server] && @options[:web_server] == "nginx"
      print_header "Installing Nginx web server ..."
      Dir.chdir("#{@options[:prefix]}/#{NGINX}")
      cmd "./configure --prefix=/opt/nginx --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --user=nginx --group=nginx"
      cmd "make 2>&1; make install"
    else
      raise "Inernal error: only nginx is supported."
    end
    raise "Nginx installation failed." if $? != 0
  end

  def install_all_gems
    @gem_path = "#{@options[:prefix]}/bin/gem"
    # Update the RubyGems system software
    # FIXME: => v.2.0.0
    # cmd "#{@gem_path} update --system 1.8.25"
    GEMS.each do |gem|
      install_gem(gem)
    end
  end

  def install_gem(gem, options = "--no-document")
    print_header "Installing #{gem} ..."
    cmd "#{@gem_path} install #{gem} #{options}"
    raise "#{gem} installation failed." if $? != 0
  end

  # install_redis
  # This method installs redis
  def install_redis
    print_header "Installing redis ..."

    Dir.chdir("#{@options[:prefix]}/#{REDIS}/src")
    cmd "make 2>&1; make PREFIX=#{@options[:prefix]} install"
    raise "Redis installation failed." if $? != 0

    `mkdir #{@options[:prefix]}/etc` unless File.exist? "#{@options[:prefix]}/etc"
    #cmd "cp ../redis.conf #{@options[:prefix]}etc"
    redis_conf_file = File.new("#{@options[:prefix]}/etc/redis.conf", 'w')
    File.foreach("../redis.conf") do |line|
      # daemonize no   --> daemonize yes
      # logfile stdout --> logfile /var/log/redis.log
      if line =~ /^daemonize/
        redis_conf_file << "daemonize yes" << "\n"
      elsif line =~ /^logfile/
        redis_conf_file << "logfile /var/log/redis.log"  << "\n"
      else
        redis_conf_file << line
      end
    end
    redis_conf_file.close
  end

  def install_sqlite
    print_header "Installing sqlite3 ..."
    Dir.chdir("#{@options[:prefix]}/#{SQLITE3}")
    cmd "./configure --prefix=#{@options[:prefix]}"
    cmd "make 2>&1; make install"
    raise "Installation of sqlite3 libraries failed." if $? != 0
  end

  def install_rhoconnect
    print_header "Building rhoconnect gem ..."
    Dir.chdir("#{@options[:prefix]}/installer")

    cmd "#{@options[:prefix]}/bin/bundle config build.sqlite3 " +
        "--with-sqlite3-include=#{@options[:prefix]}/include " +
        "--with-sqlite3-lib=#{@options[:prefix]}/lib"
    gem_name = (Dir.glob "rhoconnect-*.gem")[0]
    if gem_name && File.exists?(gem_name)
      install_gem(gem_name)
    else
      cmd "#{@options[:prefix]}/bin/bundle install --system --binstubs=/opt/rhoconnect/bin --without=test development"
      cmd "PATH=#{@options[:prefix]}/bin:$PATH rake build"
      cmd "#{@gem_path} install pkg/rhoconnect-*.gem --no-ri --no-rdoc"
      raise "Gem installation failed." if $? != 0
    end
  end
end
