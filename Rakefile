require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development, :test, :build)

load File.join(File.dirname(__FILE__) ,'tasks', 'redis.rake')
load File.join(File.dirname(__FILE__) ,'installer', 'utils', 'nix_installation.rake')
load File.join(File.dirname(__FILE__) ,'installer', 'utils', '', 'package_upload', 'repos.rake')

require 'yaml'
$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhoconnect'

include Rake::DSL
#task :default => 'spec:all'
#task :default => ["npm_install","spec:all","jasmine:headless"]
task :default => ["npm_install","spec:all"]
task :spec => 'spec:spec'

begin
  require 'rspec/core/rake_task'

  TYPES = {
    :spec => 'spec/*_spec.rb',
    :perf => 'spec/perf/*_spec.rb',
    :server => 'spec/server/*_spec.rb',
    :api => 'spec/api/**/*_spec.rb',
    :bulk => 'spec/bulk_data/*_spec.rb',
    :jobs => 'spec/jobs/*_spec.rb',
    :stats => 'spec/stats/*_spec.rb',
    :ping => 'spec/ping/*_spec.rb',
    :generator => 'spec/generator/*_spec.rb',
    :bench     => 'bench/spec/*_spec.rb',
    :controllers => 'spec/controllers/**/*_spec.rb',
    :models    => 'spec/models/**/*_spec.rb',
    :cli => 'spec/cli/*_spec.rb'
  }

  TYPES.each do |type,files|
    desc "Run specs in #{files}"
    RSpec::Core::RakeTask.new("spec:#{type}") do |t|
      t.rspec_opts = ["-b", "-c", "-fd"]
      t.pattern = FileList[TYPES[type]]
      t.rcov = false
    end
  end

  desc "Run specs in spec/**/*_spec.rb "
  RSpec::Core::RakeTask.new('spec:all') do |t|
    t.rspec_opts = ["-b", "-c", "-fd"]
    t.pattern = FileList[TYPES.values]
  end

  desc "Run doc generator - dumps out doc/protocol.html"
  RSpec::Core::RakeTask.new('doc') do |t|
    t.pattern = FileList['spec/doc/*_spec.rb']
    t.rcov = false
  end

rescue LoadError
  # Array of groups whose gems are not installed
  # if bundle install called with the --without option
  unless Bundler.settings.without.include? :test
    puts "rspec / simplecov not available. Install with: "
    puts "gem install rspec simplecov\n\n"
  end
end

# desc "Build rhoconnect gem"
# task :gem => [ 'spec:all', 'clobber_spec:all', :gemspec, :build ]
task :build => :npm_install

desc "install npm dependency packages"
task :npm_install do
  system "npm install"
end


desc "Run benchmark scripts"
task :bench do
  login = ask "login: "
  password = ask "password: "
  prefix = 'bench/scripts/'
  suffix = '_script.rb'
  list = ask "scripts(default is '*'): "
  file_list = list.empty? ? FileList[prefix+'*'+suffix] : FileList[prefix+list+suffix]
  file_list.each do |script|
    sh "bench/bench start #{script} #{login} #{password}"
  end
end

def ask(msg)
  print msg
  STDIN.gets.chomp
end

Bundler::GemHelper.install_tasks

require 'rhoconnect/version'

desc "Build archive rhoconnect-#{Rhoconnect::VERSION}.tar.gz into the pkg directory"
task :archive do
  `mkdir -p pkg`
  `git archive --format=tar --prefix=rhoconnect-#{Rhoconnect::VERSION}/ HEAD | gzip > pkg/rhoconnect-#{Rhoconnect::VERSION}.tar.gz`
end

# Debian and RPM package building tasks
def build_pkg(dist, arch, deps)
  start_dir = Dir.pwd
  build_dir      = "/tmp/rhobuild"
  version        = Rhoconnect::VERSION
  description    = '"Rhoconnect production environment"'
  prefix         = "/opt/rhoconnect/installer"
  gem_name       = "rhoconnect-#{version}.gem"

  before_install_script = "#{build_dir}/unix-like/pre_install.sh"
  after_install_script  = "#{build_dir}/unix-like/post_install.sh"
  before_remove_script  = "#{build_dir}/unix-like/pre_uninstall.sh"
  after_remove_script   = "#{build_dir}/unix-like/post_uninstall.sh"

  `rm -rf #{build_dir}` if File.exist?("#{build_dir}")
  Dir.mkdir("#{build_dir}")
  Dir.mkdir("#{build_dir}/unix-like")

  # Copy all necessary Files into the build_dir
  system("cp install.sh Gemfile Gemfile.lock #{build_dir}")
  system("cp -r installer/unix-like/*.sh #{build_dir}/unix-like")
  system("cp -r installer/unix-like/*.rb #{build_dir}/unix-like")
  system("cp pkg/#{gem_name} #{build_dir}")

  # cd into the pkg dir so that fpm will create the package into the pkg dir.
  Dir.chdir("./pkg") # it created by build task and should already exist

  # Construct fpm command
  fpm_cmd = "fpm -s dir -t #{dist} -n rhoconnect -v #{version} -a #{arch} -C #{build_dir} --epoch 1 " +
    "--before-install #{before_install_script} --after-install #{after_install_script} " +
    "--before-remove #{before_remove_script} --after-remove #{after_remove_script} " +
    "--prefix #{prefix} --description #{description}"
  # Add the list of dependencies to the fpm call
  deps.each { |dep| fpm_cmd << " -d '#{dep}'" }
  fpm_cmd << " './'"
  # Create the package
  system(fpm_cmd)
  # Leave no trace...
  system("rm -rf #{build_dir}")
  Dir.chdir(start_dir)
end

DEB_DEPS = [
  "wget (>= 1.0)", "make (>= 3.0)", "patch (>= 2.0)",
  "build-essential (>= 0)", "libc6-dev (>= 0)",
  "autoconf (>= 0.0)", "automake (>= 0.0)", "libtool (>= 0.0)",
  "zlib1g (>= 1.2.3)", "zlib1g-dev (>= 1.2.3)",
  "openssl (>= 1.0.0)", "libssl1.0.0 (>= 0)", "libssl-dev (>= 1.0.0)",
  "libcurl4-openssl-dev (>= 0)",
  "libreadline6 (>= 0)", "libreadline6-dev (>= 0)",
  "libyaml-dev (>= 0)", "libxml2-dev (>= 0)",
  "libpcre3 (>=0)", "libpcre3-dev (>=0)", "git (>= 0)"
]

desc "Build Debian DEB rhoconnect-#{Rhoconnect::VERSION}_all.deb package into the pkg directory"
task "build:deb"  => :build do
  build_pkg "deb", "all", DEB_DEPS
end

RPM_DEPS = [
  "wget >= 1.0", "make >= 3.0", "patch >= 2.0", "gcc-c++ >= 4.1.2",
  "autoconf >= 0.0", "automake >= 0.0", "libtool >= 0.0",
  "zlib >= 1.2.3", "zlib-devel >= 1.2.3",
  "curl >= 7.15.5", "curl-devel >= 7.15.5",
  "pcre >= 6.6", "pcre-devel >= 6.6",
  "openssl >= 0.9.8e", "openssl-devel >= 0.9.8e",
  "readline >= 5.1", "readline-devel >= 5.1",
  "libyaml >= 0.0", "libyaml-devel >= 0.0",
  "libffi >= 0", "libffi-devel >= 0", "git >= 0.0"
]

desc "Build Red Hat RPM rhoconnect-#{Rhoconnect::VERSION}.noarch.rpm package into the pkg directory"
task "build:rpm" => :build do
  build_pkg "rpm", "noarch", RPM_DEPS
end

begin
  require 'jasmine'
  load File.join(File.dirname(__FILE__) ,'tasks', 'jasmine.rake')
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end
