Execute.define_task do
  desc "redis-start", 'Start redis on localhost'
  def redis_start
    redis_array = config[:redis]
    RedisRunner.start(redis_array)
  end
end