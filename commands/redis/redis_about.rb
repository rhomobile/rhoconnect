Execute.define_task do
  desc "redis-about", 'About redis'
  def redis_about
    puts "\nSee http://redis.io/ for information about redis.\n\n"
  end
end