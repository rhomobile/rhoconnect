require 'rspec'
require_relative "../../lib/rhoconnect"
require_relative "../../generators/rhoconnect"

describe "Generator" do
  appname = 'mynewapp'
  source = 'mysource'
  path = File.expand_path(File.join(File.dirname(__FILE__)))

  before(:each) do
    FileUtils.mkdir_p '/tmp'
  end

  describe "AppGenerator" do
    it "should complain if no name is specified" do
      lambda {
        Rhoconnect::AppGenerator.new()
      }.should raise_error(Thor::RequiredArgumentMissingError)
    end

    it "should create new ruby application files" do
      allow(SecureRandom).to receive(:hex).with(64)
      Dir.chdir '/tmp' do
        FileUtils.rm_rf(appname)
        Bundler.with_clean_env do
          generator = Rhoconnect::AppGenerator.new([appname])
          generator.invoke_all
          Dir.chdir(appname) do
            [
              'Gemfile',
              ".rcgemfile",
              'Rakefile',
              "controllers/ruby/application_controller.rb",
              'spec/controllers/ruby/application_controller_spec.rb',
              'config.ru',
              'public',
              'settings/settings.yml',
              'spec/spec_helper.rb'
            ].each do |template|
              File.exist?("/tmp/#{appname}/#{template}").should be true
            end
          end
        end
      end
    end

    it "should create new js application files" do
      allow(SecureRandom).to receive(:hex).with(64)
      Dir.chdir '/tmp' do
        FileUtils.rm_rf(appname)
        Bundler.with_clean_env do
          Rhoconnect::AppGenerator.start([appname, '--js'])
          Dir.chdir(appname) do
            [
              'Gemfile',
              ".rcgemfile",
              'package.json',
              'Rakefile',
              'controllers/js/application_controller.js',
              'config.ru',
              'public',
              'settings/settings.yml'
            ].each do |template|
              File.exist?("/tmp/#{appname}/#{template}").should be true
            end
          end
        end
      end
    end
  end

  describe "SourceGenerator" do

    it "should complain if no name is specified" do
      lambda {
        Rhoconnect::SourceGenerator.new()
      }.should raise_error(Thor::RequiredArgumentMissingError)
    end

    it "should create new source adapter and spec" do
      Dir.chdir '/tmp' do
        FileUtils.rm_rf(appname)
        Bundler.with_clean_env do
          Rhoconnect::AppGenerator.start([appname])
          Dir.chdir appname do
            Rhoconnect::SourceGenerator.start([source])

            File.exist?("/tmp/#{appname}/models/ruby/#{source}.rb").should be true
            File.exist?("/tmp/#{appname}/controllers/ruby/#{source}_controller.rb").should be true
            File.exist?("/tmp/#{appname}/spec/models/ruby/#{source}_spec.rb").should be true
            File.exist?("/tmp/#{appname}/spec/controllers/ruby/#{source}_controller_spec.rb").should be true
          end
        end
      end
    end
  end

end
