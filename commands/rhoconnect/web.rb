Execute.define_task do
  desc "web", "Launch the web console in a browser"
  def web
    url = config[:syncserver]
    windows? ? system("start #{url}") : system("open #{url}")
  end
end