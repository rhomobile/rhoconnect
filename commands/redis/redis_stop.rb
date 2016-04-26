Execute.define_task do
  desc "redis-stop", 'Stop redis running on localhost'
  def redis_stop
    redis_array = config[:redis]
    RedisRunner.stop(redis_array)
  end
end