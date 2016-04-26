Execute.define_task do
  desc "app NAME [--js]", "Generate a new rhoconnect application"
  def app(name, platform=nil)
    # ARGV = [command, argument, ... option, ...]
    ARGV.shift
    invoke :app_generator
  end
end