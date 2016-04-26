Execute.define_task do
  desc "model NAME [--js]", "Generate a new source adapter model", :hide => true
  def model(name, platform='ruby')
    # ARGV = [command, argument, ... option, ...]
    ARGV.shift
    invoke :model_generator
  end
end