# Inspired by rabbitmq.rake the Redbox project at http://github.com/rick/redbox/tree/master
require_relative '../lib/rhoconnect/utilities'
require_relative '../commands/utilities/redis_runner'
include Utilities
include Rake::DSL

REDIS_RELEASE = "2.8.17"

namespace :redis do
  desc 'About redis'
  task :about do
    puts "\nSee http://redis.io/ for information about redis.\n\n"
  end

  desc 'Start redis'
  task :start do
    RedisRunner.start
  end

  # desc 'Start redis' without dtach - for Rhostudio (internal)
  task :startbg do
    RedisRunner.startbg
  end

  desc 'Stop redis'
  task :stop do
    RedisRunner.stop
  end

  desc 'Restart redis'
  task :restart do
    RedisRunner.stop
    RedisRunner.start
  end

  desc 'Attach to redis dtach socket'
  task :attach do
    RedisRunner.attach
  end

  desc 'Install the latest verison of Redis from Github (requires git, duh)'
  task :install => [:about, :download, :make] do
    unless windows?
	    ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"

	    mk_bin_dir(bin_dir)
	    %w(redis-benchmark redis-cli redis-server).each do |bin|
	      sh "cp /tmp/redis/src/#{bin} #{bin_dir}"
	    end
	    puts "Installed redis-benchmark, redis-cli and redis-server to #{bin_dir}"

	    ENV['PREFIX'] and conf_dir = "#{ENV['PREFIX']}/etc" or conf_dir = "#{RedisRunner.prefix}etc"
	    unless File.exists?("#{conf_dir}/redis.conf")
	      sh "mkdir #{conf_dir}" unless File.exists?("#{conf_dir}")
	      sh "cp /tmp/redis/redis.conf #{conf_dir}/redis.conf"
	      puts "Installed redis.conf to #{conf_dir} \n You should look at this file!"
	    end
    end
	end

  task :make do
    unless windows?
      sh "cd #{RedisRunner.redisdir} && make clean"
      sh "cd #{RedisRunner.redisdir} && make"
    end
  end

  desc "Download package"
  task :download do
    unless windows?
      system 'rm -rf /tmp/redis/' if File.exists?("#{RedisRunner.redisdir}")
      system 'git clone git://github.com/antirez/redis.git /tmp/redis -n'
      system "cd #{RedisRunner.redisdir} && git reset --hard && git checkout #{REDIS_RELEASE}"
    else
      puts "Not implemented on Windows"
    end
  end
end

namespace :dtach do
  desc 'About dtach'
  task :about do
    puts "\nSee http://dtach.sourceforge.net/ for information about dtach.\n\n"
  end

  desc 'Install dtach 0.8 from source'
  task :install => [:about] do
    unless windows?
      Dir.chdir('/tmp/')
      unless File.exists?('/tmp/dtach-0.8.tar.gz')
        require 'net/http'

        url = 'http://downloads.sourceforge.net/project/dtach/dtach/0.8/dtach-0.8.tar.gz'
        open('/tmp/dtach-0.8.tar.gz', 'wb') do |file| file.write(open(url).read) end
      end

      unless File.directory?('/tmp/dtach-0.8')
        system('tar xzf dtach-0.8.tar.gz')
      end

      ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"

      mk_bin_dir(bin_dir)

      Dir.chdir('/tmp/dtach-0.8/')
      sh 'cd /tmp/dtach-0.8/ && ./configure && make'
      sh "cp /tmp/dtach-0.8/dtach #{bin_dir}"

      puts "Dtach successfully installed to #{bin_dir}"
    end
  end
end
