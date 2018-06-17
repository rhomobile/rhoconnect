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
  gem 'async-rack'
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
  gem 'aws-s3', '>= 0.6.2', :require => 'aws/s3'
  gem 'sqlite3', ">= 1.3.3", :platforms => [:ruby, :mswin, :mingw]
  gem "excon", "~> 0.22.1"
  gem "net-ssh", "~> 4.2.0"
  gem "fog", "~> 1.11.1"
  gem 'ffaker', '~> 1.14.0'
  gem 'webmock', '~> 1.9.0'
end

group :test do
  gem 'rspec', '~> 2.14.0'
  gem 'simplecov', '>= 0.7.1', :require => false
  gem 'simplecov-rcov', '~> 0.2.3'
  gem 'rack-test', '~> 0.6', :require => 'rack/test'
  gem 'jasmine', :platforms => [:ruby,:jruby]
  gem 'jasmine-headless-webkit', '~> 0.8.4', :platforms => [:ruby,:jruby]
end

group :build do
  gem 'fpm', '>= 0.4.26'
end
