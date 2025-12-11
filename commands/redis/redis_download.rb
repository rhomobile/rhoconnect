REDIS_RELEASE = "2.8.17"
Execute.define_task do
  desc "redis-download", "Download redis release #{REDIS_RELEASE}"
  def redis_download
    unless windows?
      system 'rm -rf /tmp/redis/' if File.exist?("#{RedisRunner.redisdir}")
      system 'git clone git://github.com/antirez/redis.git /tmp/redis -n'
      system "cd #{RedisRunner.redisdir} && git reset --hard && git checkout #{REDIS_RELEASE}"
    else
      puts "Not implemented on Windows"
    end
  end
end