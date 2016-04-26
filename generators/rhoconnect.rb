require 'thor'
require 'thor/group'

module Rhoconnect

  class AppGenerator < Thor::Group
    namespace :app_generator
    include Thor::Actions

    argument :name
    class_options :js => false
    source_root File.join(File.dirname(__FILE__), 'templates', 'application')

    def gem_version; VERSION; end

    def copy_files
      @secret = SecureRandom.hex(64) rescue '<changeme>'
      template("config.ru", "#{name}/config.ru")
      template("Gemfile", "#{name}/Gemfile")

      copy_file "gitignore", "#{name}/.gitignore"
      copy_file 'rcgemfile', "#{name}/.rcgemfile"
      copy_file 'Rakefile', "#{name}/Rakefile"
      copy_file 'settings/settings.yml', "#{name}/settings/settings.yml"
      empty_directory File.join("#{name}", 'public')

      if options[:js]
        copy_file 'controllers/js/application_controller.js', "#{name}/controllers/js/application_controller.js"
        # TODO: spec files for js app ...

        npm_install_note = <<_NPM_INSTALL_

In the future, to ensure that all the JavaScript dependencies in your
rhoconnect application are available execute these commands:
cd #{name} && npm install

_NPM_INSTALL_

        copy_file 'package.json', "#{name}/package.json"
        say npm_install_note, :bold
        Dir.chdir(name) { system("npm install") }
        # NB: The following does not work with JRuby (1.7.7)
        # system("npm install", :chdir => name)
      else # Ruby app ...
        copy_file 'controllers/ruby/application_controller.rb', "#{name}/controllers/ruby/application_controller.rb"
        copy_file 'spec/application_controller_spec.rb', "#{name}/spec/controllers/ruby/application_controller_spec.rb"
        copy_file 'spec/spec_helper.rb', "#{name}/spec/spec_helper.rb"
      end
    end

    def after_run
      install_gems_note = <<_BUNDLE_INSTALL_

In the future, to ensure that all the dependencies in your rhoconnect application
are available execute these commands:
cd #{name} && bundle install

If you're setting up the application in a production environment run the following:
cd #{name} && bundle install --without=test development

_BUNDLE_INSTALL_

      running_bundler_first_time = <<_RUN_BUNDLER

Executing 'bundle install' for the first time in your freshly baked application!
bundle install --gemfile=#{destination_root}/#{name}/Gemfile

_RUN_BUNDLER

      gem_name, gem_ver_reqs = 'rhoconnect', gem_version
      found_gspec = Gem::Specification.find_by_name(gem_name, gem_ver_reqs)
      if found_gspec
        say running_bundler_first_time, :bold
        system("bundle install --gemfile=#{destination_root}/#{name}/Gemfile")
        say install_gems_note, :bold
      end
    rescue Exception => e
      warning_msg = "\n" +
        "*** Warning: Generatior failed to run bundler. ***\n" +
        "*** Install required version of rhoconnect gem, or explicitly ***\n" +
        "*** define in Gemfile the source to the gem using :path option. ***\n" +
        "\n"
      say warning_msg, :red
    end
  end

  class BaseSourceGenerator < Thor::Group
    include Thor::Actions

    argument :name
    class_options :js => false

    def class_name
      Thor::Util.camel_case(name.gsub('-', '_'))
    end

    def underscore_name
      Thor::Util.snake_case(name)
    end
  end

  class ModelGenerator < BaseSourceGenerator
    namespace :model_generator
    source_root File.join(File.dirname(__FILE__), 'templates', 'source')

    def create_model_and_specs
      if options[:js]
        template('models/js/model.js', "models/js/#{underscore_name}.js")
      else
        template('models/ruby/model.rb', "models/ruby/#{underscore_name}.rb")
        template('models/ruby/model_spec.rb', "spec/models/ruby/#{underscore_name}_spec.rb")
        # Edit settings.yml file
        settings_file = File.join(destination_root,'settings','settings.yml')
        settings = YAML.load_file(settings_file)
        settings[:sources] ||= {}
        settings[:sources][class_name] = {:poll_interval => 300}
        File.open(settings_file, 'w' ) do |f|
          f.write "#Sources" + {:sources => settings[:sources]}.to_yaml[3..-1]
          envs = {}
          [:development,:test,:production].each { |env| envs[env] = settings[env] }
          f.write envs.to_yaml[3..-1]
          # write all other settings
          [:development, :test, :production, :sources].each { |key| settings.delete(key) }
          f.write settings.to_yaml[3..-1] unless settings.empty?
        end
      end
    end
  end

  class ControllerGenerator < BaseSourceGenerator
    namespace :controller_generator
    source_root File.join(File.dirname(__FILE__), 'templates', 'source')

    def create_controller_and_specs
      if options[:js]
        template('controllers/js/controller.js', "controllers/js/#{underscore_name}_controller.js")
      else
        template('controllers/ruby/controller.rb', "controllers/ruby/#{underscore_name}_controller.rb")
        template('controllers/ruby/controller_spec.rb', "spec/controllers/ruby/#{underscore_name}_controller_spec.rb")
      end
    end
  end

  class SourceGenerator < BaseSourceGenerator
    namespace :source_generator

    invoke :controller_generator
    invoke :model_generator
  end

end
