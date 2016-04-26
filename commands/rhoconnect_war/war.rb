Execute.define_task do
  desc "war", "Build executable WAR file to be used in Java App Servers"
  def war
    if jruby? then
      require 'rake'
      puts "building the WAR file"
      if not File::exists? "config/warble.rb"
        puts "generating Warbler's config file"
        includeDirs = []
        Dir.mkdir('config') if not File.exists?('config')
        aFile = File.new("config/warble.rb", "w+")
        if aFile
          includeDirs = FileList['*'].exclude do |entry|
            entry if (not File.directory? entry) || (entry == 'spec')
          end
          configFile = "Warbler::Config.new do |config|\n" +
            "  config.dirs = %w(#{includeDirs.join(' ')})\n" +
            "  config.includes = FileList[\"./*\", \".rcgemfile\"]\n" +
            "  config.excludes = FileList[\"./*.war\",'spec']\nend"
          aFile.write("#{configFile}")
          aFile.close
        else
          puts "Unable to create config/warble.rb file!"
        end
      end
      # build the executable WAR using the config/warble.rb file
      ENV['BUNDLE_WITHOUT'] = ['development','test'].join(':')
      system 'bundle exec warble executable war'
    else
      puts "Cannot build WAR files outside of JRuby environment!"
    end
  end
end