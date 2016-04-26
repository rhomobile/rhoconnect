Execute.define_task do
  desc "redis-startbg", "'Start redis' without dtach - for Rhostudio (internal)", :hide => true
   def redis_startbg
    redis_array = config[:redis]
    RedisRunner.startbg(redis_array)
  end
end