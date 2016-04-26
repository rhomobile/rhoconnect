require 'rspec'
require 'thor'
require 'tmpdir'

require_relative '../../lib/rhoconnect'
include Rhoconnect

require_relative '../../commands/utilities/redis_runner'
require_relative "../../lib/rhoconnect/utilities"
include Utilities

RHOCONNECT_PORT  = 9292
REDIS_SERVER_URL = "localhost:6379"
PUSH_SERVER_URL  = "http://someappname@localhost:8675/"
API_TOKEN        = "my-rhoconnect-token"

describe "RhoconnectCommandLineInterface" do
  class Execute < Thor
    no_tasks {
      def self.define_task(&block)
        Execute.class_eval(&block)
      end

      # Disable dtach usage for rspec examples
      def dtach_installed?
        false
      end
    }
  end

  tasks = [ 'generators', 'rhoconnect', 'redis' ]
  unless windows?
    tasks << 'dtach'
    tasks << 'rhoconnect_attach' unless jruby?
  end
  tasks << if jruby? then "rhoconnect_war" else "rhoconnect_console" end
  tasks << 'rhoconnect_spec' if File.exists?(File.join(Dir.pwd,'Gemfile'))
  tasks.each do |dir|
    Dir.glob(File.join(File.dirname(__FILE__),  "..", "..", "commands", "#{dir}", "*.rb")) do |file|
      require file
    end
  end

  # Captures $stdout and $stderr into strings
  def capture_io
    require 'stringio'

    orig_stdout, orig_stderr         = $stdout, $stderr
    captured_stdout, captured_stderr = StringIO.new, StringIO.new
    $stdout, $stderr                 = captured_stdout, captured_stderr

    yield

    return captured_stdout.string, captured_stderr.string
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  def run_in_sandbox
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir) do
        # Run example in a sandbox on the file system
        yield
      end
    end
  end

  after(:each) do
    pid = `cat /tmp/rhoconnect.pid` if File.exist?("/tmp/rhoconnect.pid")
    puts "\nExecuting 'rhoconnect stop' command ..." if pid
    Execute.start ["stop"] # 'rhoconnect stop'
    File.exist?("/tmp/rhoconnect.pid").should == false
    # `ps -p #{pid} -o pid=`.should be_empty if pid
  end

  it "'rhoconnect help' cmd should display list of available commands" do
    run_in_sandbox do
      out = capture_io{ Execute.start ["help"] }.join ''
      out.strip.should start_with "Commands:"
    end
  end

  it "'rhoconnect version' cmd should display gem version" do
    run_in_sandbox do
      out = capture_io{ Execute.start ["version"] }.join ''
      out.strip.should == Rhoconnect::VERSION
    end
  end

  it "'rhoconnect routes' cmd should display list of available routes" do
    Dir.chdir(File.join(File.dirname(__FILE__),  "..", "apps", "rhotestapp")) do
      out = capture_io{ Execute.start ['routes'] }.join ''
      out.strip.should include("SampleAdapterController: /app/v1/SampleAdapter")
      out.strip.should include("FixedSchemaAdapterController: /app/v1/FixedSchemaAdapter")
      out.strip.should_not include("FooAdapterController: /app/v1/FooAdapter")
    end
  end

  it "'rhoconnect start' cmd should start blank app from any directory" do
    run_in_sandbox do
      thread = Thread.new do
        puts "Executing 'rhoconnect start' command ..."
        # Array of params expected
        Execute.start ["start"] # 'rhoconnect start'
      end
      30.times do
        sleep 1
        raise "'rhoconnect start' failed to start with exception" if thread.status.nil?
        break if File.exist?("/tmp/rhoconnect.pid")
      end
      File.exist?("/tmp/rhoconnect.pid").should == true
      pid = `cat /tmp/rhoconnect.pid`
      puts "Rhoconnect app is running with pid=#{pid}"
      `ps -p #{pid} -o pid=`.should_not be_empty
    end
  end
end
