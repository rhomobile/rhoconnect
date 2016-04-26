Execute.define_task do
  desc "controller NAME [--js]", "Generate a new source adapter controller", :hide => true
  def controller(name, platform='ruby')
    # ARGV = [command, argument, ... option, ...]
    ARGV.shift
    invoke :controller_generator
  end
end