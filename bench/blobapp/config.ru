#!/usr/bin/env ruby
require 'rhoconnect/application/init'

Rhoconnect::Server.set     :secret, '096a8a4212b18d2b281d377f2c350421898a21fec78ac1baf5482c68ee41b30dcc46309cc2fb51ccc37f24789eeaed673a291efdfd0ec42df9f62351e71806f8'

# !!! Add your custom initializers and overrides here !!!
# For example, uncomment the following line to enable Stats
#Rhoconnect::Server.enable  :stats

# Setup the url map
# run RhoConnect Application
run Rhoconnect.app