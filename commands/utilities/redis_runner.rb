require 'redis'
require 'socket'

class RedisRunner
  def self.prefix
    "/usr/local/"
  end

  def self.redisdir
    "/tmp/redis/"
  end

  def self.redisconfdir
    server_dir = File.dirname(`which redis-server`)
    conf_file = "#{RedisRunner.prefix}etc/redis.conf"
    conf_file = "#{server_dir}/redis.conf" unless File.exist? conf_file
    conf_file
  end

  def self.dtach_socket
    '/tmp/redis.dtach'
  end

  def self.local_ip?(address)
    (address == "localhost") || (address == "127.0.0.1")
  end

  def self.running?(inst = nil)
    host, port = "localhost", 6379
    host, port = inst.split(':')[0..1] if inst
    Redis.new(:host => host, :port => port).ping =~ /PONG/
  rescue
    false
  end

  def self.start(redis_array)
    if windows?
      # TODO: There's no support for redis array on Windows.
      # An alpha version of Redis 2.6 was released 01/22/2013 (https://github.com/MSOpenTech/redis)
      puts "*** Warning: Redis array is not implemented on Windows" if redis_array.size > 1
      puts "Starting redis in a new window..."
      system "start #{File.join(redis_home,'redis-server')} #{File.join(redis_home,'redis.conf')}" rescue
        "redis-server not installed on your path, please install redis."
    elsif (redis_array.size == 1)
      host, port = redis_array[0].split(':')[0..1]
      puts "Starting redis server ..."
      if defined?(JRUBY_VERSION)
        command = "redis-server --port #{port} &"
      else
        puts 'Detach with Ctrl+\  Re-attach with rhoconnect redis-attach'
        sleep 1
        command = "dtach -A #{dtach_socket} redis-server --port #{port}"
      end
      system command
    else
      puts "Starting redis servers ..."
      redis_array.each do |cfg|
        host, port = cfg.split(':')[0..1]
        system("redis-server --port #{port} &") if RedisRunner.local_ip?(host)
      end
    end
  end

  # this function is used with Rhostudio where there is no terminal
  def self.startbg(redis_array)
    if windows?
      puts "Starting redis in a new window..."
      system "start \"\" #{File.join(redis_home,'redis-server')} #{File.join(redis_home,'redis.conf')}" rescue
        "redis-server not installed on your path, please install redis."
    else
      puts "Starting redis ..."
      redis_array.each do |cfg|
        host, port = cfg.split(':')[0..1]
        system("redis-server --port #{port} > /dev/null 2>&1 &") if RedisRunner.local_ip?(host)
      end
    end
  end

  def self.attach
    system "dtach -a #{dtach_socket}"
  end

  def self.stop(redis_array)
    if windows?
      Redis.new.shutdown rescue nil
    else
      redis_array.each do |cfg|
        host, port = cfg.split(':')[0..1]
        Redis.new(:port => port).shutdown rescue nil if RedisRunner.local_ip?(host)
      end
    end
  end

  def self.flushdb (redis_array)
    if windows?
      Redis.new.flushdb rescue nil
    else
      redis_array.each do |cfg|
        host, port = cfg.split(':')[0..1]
        Redis.new(:port => "#{port}").flushdb rescue nil if RedisRunner.local_ip?(host)
      end
    end
  end

end