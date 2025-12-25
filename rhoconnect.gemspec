# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rhoconnect/version'

Gem::Specification.new do |s|
  s.name        = 'rhoconnect'
  s.version     = Rhoconnect::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Rhomobile']
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.email       = %q{dev@rhomobile.com}
  s.homepage    = %q{http://rhomobile.com/products/rhoconnect}
  s.summary     = %q{RhoConnect App Integration Server}
  s.description = %q{RhoConnect App Integration Server and related command-line utilities}

  s.rubyforge_project = nil

  s.files        = %w(
    CHANGELOG.md CREDITS Gemfile Gemfile.lock install.sh README.md Rakefile LICENSE Rakefile rhoconnect.gemspec
  )
  s.files       += Dir.glob('bench/**/*')
  s.files       += Dir.glob('commands/**/*')
  s.files       += Dir.glob('doc/**/*')
  s.files       += Dir.glob('examples/**/*')
  s.files       += Dir.glob('generators/**/*')
  s.files       += Dir.glob('generators/templates/application/.rcgemfile')
  s.files       += Dir.glob('installer/**/*')
  s.files       += Dir.glob('lib/**/*')
  s.files       += Dir.glob('js-adapters/**/*')
  s.files       += Dir.glob('tasks/**/*')
  s.test_files   = Dir.glob('spec/**/*')
  s.executables  = Dir.glob('bin/*').map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.rubygems_version = %q{1.5.0}
  s.extra_rdoc_files = [
    'LICENSE',
    'README.md'
  ]

  s.add_dependency('bundler', '>= 1.17.3')
  s.add_dependency('rack', '~> 2.0.6')
  s.add_dependency('sinatra', '~> 2.0.5')
  s.add_dependency('rake', '>= 12.3.2')
  s.add_dependency('json', '>= 1.8', '< 2.0')
  s.add_dependency('rubyzip', '>= 1.2.2', '< 2.1.0')
  s.add_dependency('connection_pool', '~> 2.2.2')
  s.add_dependency('redis-namespace', '~> 1.6.0')
  s.add_dependency('redis', '~> 4.1.0')
  s.add_dependency('resque', '>= 2.0.0')
  s.add_dependency('rest-client', '~> 2.1.0')
  s.add_dependency('thor', '~> 0.20.3')
  s.add_dependency('signet', '~> 0.12.0')
  s.add_dependency('google-api-client', '~> 0.44.2')
  s.add_dependency('google-api-fcm', '~> 0.1.7')
end
