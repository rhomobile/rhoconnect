Execute.define_task do
  desc "version", "Display rhoconnect version"
  def version
    puts Rhoconnect::VERSION
  end
end