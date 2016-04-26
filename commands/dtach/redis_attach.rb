Execute.define_task do
  desc "redis-attach", 'Attach to redis dtach socket'
  def redis_attach
    RedisRunner.attach
  end #redis_attach
end #do