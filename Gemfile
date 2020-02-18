source "https://rubygems.org"

# Specify your gem's dependencies in rhoconnect.gemspec
gemspec

gem 'win32-process', :platforms => [:mswin, :mingw]

# use thin and eventmachine everywhere except JRuby
platforms :ruby, :mingw  do
	gem "eventmachine", "~> 1.0.5"
	# using thin by default
	gem 'thin'
# for async framework
# for Async, Eventful execution
  gem 'rack-fiber_pool'
  gem 'async-rack', :git => 'https://github.com/tauplatform/async-rack.git'
end

platforms :jruby do
  gem 'jdbc-sqlite3', ">= 3.7.2"
  gem 'dbi', ">= 0.4.5"
  gem 'dbd-jdbc', ">= 0.1.4"
  gem 'jruby-openssl', ">= 0.7.4"
  gem 'puma', "~> 1.6.3"
  gem 'warbler'
end

group :development do
  # gem 'debugger'
  gem 'aws-s3', '>= 0.6.3', :require => 'aws/s3'
  gem 'sqlite3', ">= 1.4.0", :platforms => [:ruby, :mswin, :mingw]
  gem "excon", "~> 0.72.0"
  gem "net-ssh", "~> 5.2.0"
  gem "fog-aws", "~> 3.4.0"
  gem 'ffaker', '~> 2.10.0'
  gem 'webmock', '~> 3.5.1'
end

group :test do
  gem 'rspec', '~> 3.8.0'
  gem 'simplecov', '>= 0.16.1', :require => false
  gem 'simplecov-rcov', '~> 0.2.3'
  gem 'rack-test', '~> 1.1.0', :require => 'rack/test'
  #gem 'jasmine', :platforms => [:ruby,:jruby]
  #gem 'jasmine-headless-webkit', '~> 0.8.4', :platforms => [:ruby,:jruby]
end

group :build do
  gem 'fpm', '>= 1.11.00'
end

gem 'signet', '~> 0.7'
gem 'google-api-client', '~> 0.31.0'
gem 'google-api-fcm', '~> 0.1.7'
