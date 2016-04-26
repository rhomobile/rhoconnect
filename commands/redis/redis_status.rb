Execute.define_task do
  desc "redis-status", 'Show status of redis servers'
  def redis_status
    config[:redis].each do |redis|
      host,port = redis.split(':')[0..1]
      if RedisRunner.running?(redis)
        puts "#{host}:#{port}: server running"
      else
        puts "#{host}:#{port}: server not running"
      end
    end
  end
end