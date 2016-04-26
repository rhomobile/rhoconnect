#!/usr/bin/env ruby
require 'rhoconnect/application/init'

Rhoconnect::Server.set     :secret,      'cf8e8a1d3653fcfb2332d8b1af9f6762c3c45ea12144bb5f15cd5618cc8e453b45a02dd304bdd791489dcd1ae35b807e4b4f4e6f7faedb551e76996c0f3c11c6'

# !!! Add your custom initializers and overrides here !!!
# For example, uncomment the following line to enable Stats
#Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :logging

# Setup the url map
# run RhoConnect Application
run Rhoconnect.app