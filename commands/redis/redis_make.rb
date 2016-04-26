Execute.define_task do
  desc "redis-make", "Alias for make clean && make", :hide => true
  def redis_make
    unless windows?
      system "cd #{RedisRunner.redisdir} && make clean"
      system "cd #{RedisRunner.redisdir} && make"
    end #unless
  end #redis_make
end #do