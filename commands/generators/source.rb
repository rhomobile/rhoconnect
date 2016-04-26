Execute.define_task do
  desc "source NAME [--js]", "Generate a new source adapter"
  def source(name, platform=nil)
    # ARGV = [command, argument, ... option, ...]
    ARGV.shift
    invoke :source_generator
  end
end