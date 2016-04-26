Execute.define_task do
  desc "routes", "Prints out routes defined in the application"
  def routes
    puts ""
    puts "\tYour Application [#{Dir.pwd}] has the following routes map:"
    puts ""
    start_list = []
    begin
      redis_array = config[:redis]
      redis_array.each do |redis_inst|
        start_list << redis_inst unless RedisRunner.running?(redis_inst)
      end
      RedisRunner.startbg(start_list) unless start_list.empty?

      require 'rhoconnect/application/init'
      Rhoconnect::Server.set     :secret,      'temp_secret'
      Rhoconnect.url_map.each do |root, controller|
        puts "  #{controller.helpers.class.name}: #{root}"
        controller.helpers.class.paths.each do |verb, paths|
          paths.each do |path|
            puts "    --> #{verb.to_s.upcase}\t #{path}"
          end
        end
        # also , look in superclasses
        klass = controller.helpers.class
        superklass = controller.helpers.class.superclass
        until superklass.nil? or (superklass.name == "Sinatra::Base")
          superklass.paths.each do |verb, paths|
            paths.each do |path|
              puts "    --> #{verb.to_s.upcase}\t #{path}\t (defined in #{superklass.name})"
            end
          end
          klass = superklass
          superklass = klass.superclass
        end
      end
    rescue Exception => e
      Rhoconnect.log "#{e.inspect}"
    ensure
      Rhoconnect.shutdown
      # TODO: Something is wrong here on Windows!!!
      # if I use RedisRunner.stop - process hangs for several seconds
      system("rhoconnect redis-stop") unless start_list.empty?
    end
  end
end