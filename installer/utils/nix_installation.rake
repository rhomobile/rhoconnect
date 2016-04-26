namespace :rc_pkg do
  desc 'Test creation and installation of both DEB and RPM rhoconnect packages.'
  task :test => ['build:deb', 'build:rpm'] do
    # Run installation test
    ruby "installer/utils/nix_install_test.rb"
  end #:test
end #:rc_pkg