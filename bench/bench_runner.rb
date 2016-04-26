#!/usr/bin/env ruby
#
RHOCONNECT_PATH = ARGV[0]
LOG_FILE = ARGV[1]
orig_stdout = $stdout # redirect stdout to LOG_FILE
orig_stderr = $sdterr
$stdout = $sdterr = File.new(LOG_FILE, 'a')

puts "Script #{$0} is started at #{Time.now.to_s}"

begin
  # Check for another instance of rhoconnect application
  raise "Another instance of bench application is running." unless `cat /tmp/benchapp.pid 2> /dev/null`.empty?
  raise "Another instance of rhoconnect application is running." unless `cat /tmp/rhoconnect.pid 2> /dev/null`.empty?

  ruby_version = `rvm current`
  puts "Ruby version: #{ruby_version}"
  puts
 
  Dir.chdir(RHOCONNECT_PATH)
  puts "Checking rhoconnect dependencies ..."
  puts `bundle update`
  puts
  
  puts "Installing rhoconnect ..."
  puts `rake install`
  puts

  Dir.chdir "bench/benchapp" #puts Dir.pwd
  puts "Checking bench application dependencies ..."
  puts `bundle update`
  puts
  
  puts "Starting bench application ..."
  t = Thread.new do
    log = `rackup -D -P /tmp/benchapp.pid -s thin config.ru 2>&1`
    puts log
  end
  t.join

=begin
if ruby_version =~ /jruby/
# puts "Ruby version: #{ruby_version}"
t = Thread.new do
puts `jruby -S trinidad -p 9292 -r config.ru --load daemon --daemonize /tmp/benchapp.pid`
end
# t.join
else
pid = Process.fork do
log = `rackup -D -P /tmp/benchapp.pid -s thin config.ru`
puts log
puts
Process.exit(0)
end
Process.waitpid(pid)
end
=end

  count = 0
  unless File.exist? '/tmp/benchapp.pid'
    sleep 1
    count += 1
    # Throw exception after waiting at least 20 sec.
    raise "Error: Bench application failed to start. File /tmp/benchapp.pid does not exist." if count >= 10
  end

  pid = `cat /tmp/benchapp.pid`
  puts "Bench application is up and running with pid #{pid}"
  puts
  
# puts `echo 'yes' | rake rhoconnect:reset 2>&1`
# puts

  Dir.chdir "../"
  bench_errors = {}
  puts "Running bench scripts ..."
  %w[ cud_script query_only_script query_script query_md_script ].each do |script|
    puts "Script #{script} ..."
    log = `"./run_#{script}.sh" 2>&1`

    count = 0
    stats_found = nil
    log.each_line do |line|
      puts line if count <= 1
      count += 1
      stats_found ||= (/Statistics:/ =~ line)
      if stats_found
        puts line
        if line.match /err: (\d+), verification err: (\d+)$/
          if $1.to_i != 0 || $2.to_i != 0
            bench_errors[script] ||= []
            bench_errors[script] << line
          end
        end
      end
    end
    puts
  end
  
  if not bench_errors.empty?
    #puts "TODO: send email"
    puts "The following scripts completed with errors:"
    bench_errors.each do |script, errors|
      puts "#{script}:"
      errors.each { |err| puts " #{err}" }
    end
    exit -1
  end

rescue Exception => e
  puts e.message
  exit -1
ensure
  if File.exist? '/tmp/benchapp.pid'
    pid = `cat /tmp/benchapp.pid`
    res = `kill -9 #{pid}` if pid.to_i > 0 # `kill -s SIGINT #{pid}`
    File.delete '/tmp/benchapp.pid'
    puts "Bench application killed ..."
  end
  puts "Script #{$0} is finished at #{Time.now.to_s}"
  puts ""
  $stdout = orig_stdout #restore stdout
  $sdterr = orig_stderr #restore stderr
end
