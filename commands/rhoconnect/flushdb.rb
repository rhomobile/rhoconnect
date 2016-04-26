Execute.define_task do
  desc "flushdb", "Flush data store - WARNING: THIS REMOVES ALL DATA IN RHOCONNECT"
  def flushdb
    puts "*** WARNING: THIS WILL REMOVE ALL DATA FROM YOUR REDIS STORE ***"
    confirm = ask "Are you sure (please answer yes/no)? "
    if confirm == 'yes'
      RedisRunner.flushdb(config[:redis])
      puts "Database flushed..."
    else
      puts "Aborted..."
    end
  end
end