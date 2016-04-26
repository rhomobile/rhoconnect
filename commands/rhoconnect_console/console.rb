Execute.define_task do
desc "console [environment]", "Run rhoconnect console"
  def console(environment=nil)
    ENV['RACK_ENV'] = environment || 'development'
    controller_file = (File.exist?(File.join(Dir.pwd, 'controllers', 'ruby', 'application_controller.rb'))) ?
      File.join(Dir.pwd, 'controllers', 'ruby', 'application_controller.rb') :
      File.join(File.dirname(__FILE__), '..', '..', 'generators', 'templates', 'application', 'controllers', 'ruby', 'application_controller.rb')

    if RedisRunner.running?
      system "irb -rubygems -r #{File.join(File.dirname(__FILE__),'console_helper')} " +
        "-r #{File.join(File.dirname(__FILE__), '..', '..', 'lib', 'rhoconnect') } " +
        "-r #{File.join(File.dirname(__FILE__), '..', '..', 'lib', 'rhoconnect', 'server') } " +
        "-r #{controller_file}"
    else
      puts "Redis is not running. Please start it by running 'rhoconnect redis-start' command."
    end
  end
end