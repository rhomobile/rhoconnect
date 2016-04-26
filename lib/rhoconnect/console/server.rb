puts "\nDEPRECATION WARNING: 'rhoconnect/console/server' will be removed in 4.0. Please change your config.ru:\n\n"
puts "require 'rhoconnect/console/server'"
puts "\nto the following:\n\n"
puts "require 'rhoconnect/web-console/server'\n\n"
require 'rhoconnect/web-console/server'