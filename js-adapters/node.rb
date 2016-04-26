module Rhoconnect
  class Node

    class << self
      attr_accessor :started,:pipe
    end
    @started = false
    @pipe = nil

    def self.shell_node(opts = {})
      package_file = File.join(Dir.pwd,'package.json')
      if not File.exists?(package_file)
        Rhoconnect.use_node = false
        log "No `package.json` detected, disabling JavaScript support."
        return
      end

      if which("node")
        begin
          if @started
            kill_process(opts)
          end
          @started = true
          dir  = File.expand_path(File.dirname(__FILE__))
          pwd = Dir.pwd
          node_modules = File.join(pwd,'node_modules')
          sub_env = {
            "NODE_PATH" => "#{node_modules}#{File::PATH_SEPARATOR}#{pwd}#{File::PATH_SEPARATOR}#{dir}",
            "REDIS_URL" => Rhoconnect.redis_url
          }
          file = File.join(dir,"server.js")
          args = [
            sub_env, "node", file, Rhoconnect::NodeChannel::PUBSUB_IDENTIFIER,
            Rhoconnect.environment.to_s, Rhoconnect.base_directory
          ]
          @pipe = IO.popen(args, "w")
          log "Starting Node.js process: #{@pipe.pid}"
          @pipe
        rescue Exception=>e
          puts "Node.js startup error: #{e.message}\n"
          puts e.backtrace.join("\n")
          raise e
        end
      else
        Rhoconnect.use_node = false
        log "Node.js not detected, disabling JavaScript support."
      end
    end

    def self.kill_process(opts = {})
      log "Stopping Node.js process: #{@pipe.pid}" if @pipe
      if opts[:force]
        begin
          Process.kill('KILL', @pipe.pid)
          Process.waitpid(@pipe.pid)
        rescue
          # Process not found, don't worry about killing it
        end
      else
        NodeChannel.exit_node
      end
      @started = false
      @pipe = nil
    end

  end
end