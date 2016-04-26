#!/usr/bin/env ruby
require 'rhoconnect/application/init'

# secret is generated along with the app
Rhoconnect::Server.set     :secret,      '3ddaa72a36466bae3fc5e54c09324db50cfc30588d8dee1a2700e61195bdbbb5eeb65da2a184d274ce644b20b0e986046c2447730c85555ce18a4eb2fce7ebf5'

# !!! Add your custom initializers and overrides here !!!
# For example, uncomment the following line to enable Stats
Rhoconnect::Server.enable  :stats

# Load RhoConnect application
require './application'
require './my_server'

# Setup the url map
# run RhoConnect Application
run Rhoconnect.app