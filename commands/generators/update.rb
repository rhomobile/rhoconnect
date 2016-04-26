Execute.define_task do
  desc "update", "Update an existing application to the latest rhoconnect release"
  def update
    require 'bundler'
    Bundler.with_clean_env do
      `bundle install`
    end

    path_to_tempate = File.expand_path(File.join(File.dirname(__FILE__), '..','..', 'generators', 'templates', 'application'))
    unless File.exist?('.rcgemfile')
      require 'erb'
      File.open('Gemfile.new', 'w') do |f|
        gem_version = Rhoconnect::VERSION
        template = ERB.new(IO.read(File.join(path_to_tempate, 'Gemfile')))
        f << template.result(binding)
      end
      puts "The new Gemfile for rhoconnect version '#{Rhoconnect::VERSION}' is saved as Gemfile.new"
    end

    FileUtils.copy(File.join(path_to_tempate, 'rcgemfile'), '.rcgemfile')

    Bundler.with_clean_env do
      `bundle install`
    end
    puts "\nSee http://docs.rhomobile.com/rhoconnect/install#upgrading-an-existing-application about update details.\n\n"
  end
end
