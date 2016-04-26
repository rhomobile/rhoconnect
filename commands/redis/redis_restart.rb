Execute.define_task do
  desc "redis-restart", 'Restart redis on localhost'
  def redis_restart
    redis_array = config[:redis]
    RedisRunner.stop(redis_array)
    RedisRunner.start(redis_array)
  end
end