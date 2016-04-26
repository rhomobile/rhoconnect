# Matches all inputs
module InvalidCommand
  def self.match?(input); true; end
  def self.execute(input); end
end

#  rhoconnect [help [cmd]]
module HelpCommand
  def self.match?(input); (input == 'help'); end

  def self.execute(input)
    tasks = [ 'generators', 'rhoconnect', 'redis' ]
    unless windows?
      tasks << 'dtach'
      tasks << 'rhoconnect_attach' unless jruby?
    end
    tasks << if jruby? then "rhoconnect_war" else "rhoconnect_console" end
    tasks << 'rhoconnect_spec' if File.exists?(File.join(Dir.pwd,'Gemfile'))
    tasks.each do |dir|
      Dir.glob(File.join(File.dirname(__FILE__),  "..", "commands", "#{dir}", "*.rb")) do |file|
        next if windows? &&
          ["redis_download.rb", "redis_install.rb", "redis_make.rb"].include?(File.basename(file))
        require file
      end
    end
  end
end

# rhoconnect start|stop|restart|...
module RunTimeCommands
  def self.match?(input)
    %w[start stop restart startbg startdebug].include?(input)
  end
  def self.execute(input)
    if File.exists?(File.join(Dir.pwd,'Gemfile')) && input =~ /start/
      require 'bundler'
      Bundler.require
    end
    require_relative '../commands/rhoconnect/config'
    require_relative '../commands/utilities/redis_runner'
    %w[start stop restart startbg startdebug].each { |f| require_relative "../commands/rhoconnect/#{f}" }
  end
end

# Group of rhconnect redis-*
module RedisCommands
  def self.match?(input); input =~ /^redis/; end
  def self.execute(input)
    require_relative '../commands/utilities/redis_runner'
    require_relative '../commands/rhoconnect/config'
    %w[about start startbg restart stop status].each { |f| require_relative "../commands/redis/redis_#{f}" }
    unless windows?
      %w[download install make].each { |f| require_relative "../commands/redis/redis_#{f}" }
      require_relative '../commands/dtach/redis_attach'
    end
  end
end

# rhoconnect app|source|...
module GeneratorCommands
  def self.match?(input); %w[app controller model source update].include?(input); end
  def self.execute(input)
    require_relative "../generators/rhoconnect"
    require_relative '../lib/rhoconnect'
    include Rhoconnect
    %w[app controller model source update].each { |f| require_relative "../commands/generators/#{f}" }
  end
end

# rhoconnect version
module VersionCommand
  def self.match?(input); input == 'version'; end
  def self.execute(input)
    require_relative '../lib/rhoconnect/version'
    include Rhoconnect
    require_relative '../commands/rhoconnect/version'
  end
end

# rhoconnect secret
module SecretCommand
  def self.match?(input); input == 'secret'; end
  def self.execute(input); require_relative '../commands/rhoconnect/secret'; end
end

# rhoconnect console
module ConsoleCommand
  def self.match?(input); input == 'console'; end
  def self.execute(input)
    unless jruby?
      require_relative '../commands/utilities/redis_runner'
      require_relative '../commands/rhoconnect_console/console'
    end
  end
end

# rhoconnect web
module WebCommand
  def self.match?(input); input == 'web'; end
  def self.execute(input)
    require_relative '../commands/rhoconnect/config'
    require_relative '../commands/rhoconnect/web'
  end
end

# rhoconnect war
module WarCommand
  def self.match?(input); input == 'war'; end
  def self.execute(input); require_relative '../commands/rhoconnect_war/war' if jruby?; end
end

# rhoconnect dtach-*
module DtachCommands
  def self.match?(input); input =~ /^dtach/ || input == 'attach'; end
  def self.execute(input)
    unless windows?
      require_relative '../commands/utilities/redis_runner'
      require_relative '../commands/dtach/dtach_about'
      require_relative '../commands/dtach/dtach_install'
      require_relative '../commands/rhoconnect_attach/attach' unless jruby?
    end
  end
end

# rhoconnect flushdb
module FlushdbCommand
  def self.match?(input); input == 'flushdb'; end
  def self.execute(input)
    require_relative '../commands/rhoconnect/config'
    require_relative '../commands/utilities/redis_runner'
    require_relative '../commands/rhoconnect/flushdb'
  end
end

# rhoconnect get-token|set-admin-password
module AdminCommands
  def self.match?(input); input =~ /get[-_]token/ || input =~ /set[-_]admin[-_]password/; end
  def self.execute(input)
    require_relative '../commands/rhoconnect/config'
    require_relative '../commands/rhoconnect/get_token'
    require_relative '../commands/rhoconnect/set_admin_password'
  end
end

# rhoconnect routes
module RoutesCommand
  def self.match?(input); input == 'routes'; end
  def self.execute(input)
    if File.exists?(File.join(Dir.pwd,'Gemfile'))
      require 'bundler'
      Bundler.require
    end
    require_relative '../commands/rhoconnect/config'
    require_relative '../commands/utilities/redis_runner'
    require_relative '../commands/rhoconnect/routes'
  end
end

# rhoconnect spec
module SpecCommand
  def self.match?(input); input == 'spec'; end
  def self.execute(input)
    if File.exists?(File.join(Dir.pwd,'Gemfile'))
      require 'bundler'
      Bundler.require
      require_relative '../commands/rhoconnect_spec/spec' if Bundler.load.specs.find{ |s| s.name == 'rspec' }
    end
  end
end

commands = [
  HelpCommand, RunTimeCommands, RedisCommands, GeneratorCommands, VersionCommand,
  SecretCommand, ConsoleCommand, WebCommand, WarCommand, DtachCommands,
  FlushdbCommand, AdminCommands, RoutesCommand, SpecCommand, InvalidCommand ]

input = ARGV[0] ? ARGV[0] : 'help'
# Process user input
command = commands.find { |cmd| cmd.match?(input) }
# Load code that matches selected command
command.execute(input)
