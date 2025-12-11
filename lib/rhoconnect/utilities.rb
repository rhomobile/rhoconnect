require 'json'
require 'rbconfig'

module Utilities
  # Prints the command to be issued and then issues it to system
  def cmd(cmd)
    puts cmd
    system "#{cmd}"
  end #cmd

  def mk_bin_dir(bin_dir)
    begin
      mkdir_p bin_dir unless File.exist?(bin_dir)
    rescue
      puts "Can't create #{bin_dir}, maybe you need to run command as root?"
      exit 1
    end
  end

  def post(path,params)
    req = Net::HTTP.new($host,$port)
    resp = req.post(path, params.to_json, 'Content-Type' => 'application/json')
    print_resp(resp, resp.is_a?(Net::HTTPSuccess) ? true : false)
  end

  def print_resp(resp,success=true)
    if success
      puts "=> OK"
    else
      puts "=> FAILED"
    end
    puts "=> " + resp.body if resp and resp.body and resp.body.length > 0
  end

  def archive(path)
    File.join(path,File.basename(path))+'.zip'
  end

  def ask(msg)
    print msg
    STDIN.gets.chomp
  end

  def load_settings(file)
    begin
      $settings = YAML.load_file(file)
    rescue Exception => e
      puts "Error opening settings file #{file}: #{e}."
      puts e.backtrace.join("\n")
      raise e
    end
  end

  def rhoconnect_socket
    '/tmp/rhoconnect.dtach'
  end

  def rhoconnect_pid
    if windows?
  	  Dir.mkdir 'C:/TMP' unless File.directory? 'C:/TMP'
  	  'C:/TMP/rhoconnect.pid'
    else
      '/tmp/rhoconnect.pid'
    end
  end

  # See http://rbjl.net/35-how-to-properly-check-for-your-ruby-interpreter-version-and-os
  def windows?
    RbConfig::CONFIG['host_os']  =~ /(win|w)32$/
  end

  def redis_home
    ENV['REDIS_HOME'] || File.join($redis_dest,$redis_ver)
  end

  def supported_mri_ruby?
    RUBY_VERSION =~ /^1\.9\.\d/ || RUBY_VERSION =~ /^2\.\d+\.\d+/
  end

  def jruby?
    defined?(JRUBY_VERSION)
  end

  def thin?
    begin
      require 'thin'
      'bundle exec rackup -s thin'
    rescue LoadError
      nil
    end
  end

  def mongrel?
    begin
      require 'mongrel'
      'bundle exec rackup -s mongrel'
    rescue LoadError
      nil
    end
  end

  def report_missing_server
    msg =<<-EOF
Could not find 'thin' or 'mongrel' on your system.  Please install one:
gem install thin
or
gem install mongrel
EOF
    puts msg
    exit 1
  end

  def trinidad?
    'bundle exec jruby -S trinidad'
  end

  def dtach_installed?
    return false if windows? # n/a on windows
    `which dtach` != ''
  end

end