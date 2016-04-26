require 'rubygems'

# Set environment to test
ENV['RACK_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

# Try to load vendor-ed rhoconnect, otherwise load the gem
begin
  require 'vendor/rhoconnect/lib/rhoconnect'
rescue LoadError
  require 'rhoconnect'
end

$:.unshift File.join(File.dirname(__FILE__), "..")
# Load our rhoconnect application
require 'application'
include Rhoconnect

require 'rhoconnect/test_methods'

shared_examples "SpecHelper" do
  include Rhoconnect::TestMethods

  before(:each) do
    Store.flush_all
    Application.initializer(ROOT_PATH)
  end
end