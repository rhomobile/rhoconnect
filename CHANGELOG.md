## 5.4.0 (2015-12-08)
* Final v5.4.0 stable release
* Changed the rhoconnect logo used in the rhoconnect web console

## 5.3.0 (2015-09-11)
* Final v5.3.0 stable release
* Fix for setting rhoconnect-admin password in rhoconnect console
* Fix for displaying the document of type zset in the rhoconnect console(useful for displaying failed CUD records which are stuck in the rhoconnect server

## 5.1.1 (2015-03-13)
* Update production stack to ruby-2.2.1.

## 5.1.0 (2015-02-9)
* Final v5.1.0 stable release
* Updated eventmachine gem to latest version 1.0.5. See https://github.com/eventmachine/eventmachine/issues/457

## 5.1.0.beta.2 - 4.1.0.beta.3 (skipped for RMS version parity)

## 5.1.0.beta.1 (2014-12-29)
* Update production stack to ruby-2.2.0.

## 5.0.25 (2014-12-16)
* Final v5.0.25 stable release based on beta.25
* 80477192 - Make node_channel TIMEOUT configurable

## 5.0.beta.25 (2014-12-5)
* Update production stack to ruby-2.1.5, node v0.10.33, redis-2.8.17, and nginx-1.6.2.

## 5.0.0 (2014-07-03)
* Final v5.0.0 stable release

## 4.2.0.beta.1 (not available yet)
* Update production stack to ruby-2.1.2, support Ubuntu 14.04 LTS
* Update build tools to use Amazon Ubuntu 14.04 image
* Fix iOS push to allow non-String passphrases
* Upgrade Amazon Cent OS build images to latest stable versions (5.10 and 6.5)

## 4.1.1 (2014-03-26)
* 68317450 - 'query' SourceJob infinite loop

## 4.1.0 (2014-03-11)
* Fix for login/create different user issue

## 4.1.0.beta.32 (2014-03-06)
* Update production stack to ruby-2.1.1, redis-2.8.7, node v0.10.26, and nginx-1.4.6.

## 4.1.0.beta.26 - 4.1.0.beta.31 (skipped for RMS version parity)

## 4.1.0.beta.25 (2014-02-20)
* Fixing redis connection string for windows

## 4.1.0.beta.21 - 4.1.0.beta.24 (skipped for RMS version parity)

## 4.1.beta.20 (2014-02-10)
* Fixed broken 'rake spec:server' task
* Ruby 2.1.0 support
* Fixed `rhoconnect set-admin-password` results in Could not find command (#65307462)

## 4.1.0.beta.9 - 4.1.0.beta.19 (skipped for RMS version parity)

## 4.1.0.beta.8 (2013-12-10)
* rspec upgrade to latest version
* obsolete gem 'templater' is removed and all generator commands implemented on 'thor' API
* ruby 2.0 support
* Fixed npm installation failure in rhoconnect generator for js apps with JRuby
* Per-source settings for JS adapters (#60477032)
* Update production stack to ruby-1.9.3-p484, redis-2.6.16, node v0.10.22, and nginx-1.4.4.

## 4.1.0.beta.1 - 4.1.0.beta.7 (skipped for RMS version parity)

## 4.0.1 (2013-10-29)
* fixed issue with loading JS Store api from controller context
* spelling mistakes in docs
* Updated load path to run CLI commands directly from rhoconnect bin directory
* Added warning msg to app generator if it cannot run bundler due to missing rhoconnect version.
* Setup redis_url variable to represent connection string for redis (fixes #57611994 and #57773212)
* Use unique identifier for pubsub channel names (#58934776)

## 4.0.0 (2013-09-05)
* Final v4.0.0 stable release based on beta.63

## 4.0.0.beta.63 (2013-08-19)
* B-98911 - Fully removed BlackBerry support
* D-05224 - Fixed stdout for node process.  `console.log()` now works
* B-105930 - Add support for push_objects and push_deletes in js adapters
* B-92759 - Completely remove C2DM code
* Add check for ruby download status in rhoconnect installer

## 4.0.0.beta.46 - 4.0.0.beta.51 (skipped for RMS version parity)

## 4.0.0.beta.45 (2013-07-30)
* Fixed issue w/ securerandom loading for app-less start command
* D-05431 - Remove refs. to blackberry clients in push docs
* Update production stack to ruby-1.9.3-p448, redis-2.6.14, node v0.10.15, and nginx-1.4.2.
* Don't generate code referencing RHO_ENV. Use RACK_ENV.

## 4.0.0.beta.25 - 4.0.0.beta.44 (skipped for RMS version parity)

## 4.0.0.beta.24 (2013-06-07)
* Add /system/rps_login route to handle application credentials for push server
* Update doc for 'rhoconnect-push' config.json advanced options

## 4.0.0.beta.18-23 (skipped for RMS version parity)

## 4.0.0.beta.17 (2013-05-28)
* B-103375 - Added `rhoconnect routes` command
* D-05133 - Node.js process detection logic fails on windows
* Update production stack to ruby-1.9.3-p429
* D-05169 - Fixed issue where default options can't be overridden in JS controllers
* D-05223 - Support non-hash result value (needed for stashResult)
* Fixed recursive infinite loop in the CUD Source Job
* B-100517 - Added `find_duplicates_on_update` flag for update duplicate detection

## 4.0.0.beta.16 (skipped for RMS version parity)

## 4.0.0.beta.15 (skipped for RMS version parity)

## 4.0.0.beta.14 (2013-05-14)
* B-101474 - Remove Ruby 1.8.7 support
* D-04477 - Rack::Session::Cookie security warning printing on every http request
* B-106356 - Update nginx package to 1.4.1 (CVE-2013-2028)
* B-105908 - Additional JS API methods: partitionName and exceptions
* B-105504 - Boilerplate handling of store blob function should return error
* TK-190698 - Support generic CUD queue (multi-source and interim states)

## 4.0.0.beta.13 (skipped for RMS version parity)

## 4.0.0.beta.12 (2013-04-26)
* B-104783 - Add Node package dependency for Ubuntu/CentOS packages
* B-91486 - Redis custom partitions
* B-99049 - Implement 4.0 routes support in RhoConnect-Client
* B-104736 - Additional JS API methods added:
  * Store: getData, putData, getValue, putValue
  * Model: stashResult, storeBlob, getData(md)
* B-104738 - JS API documentation now available on edgedocs

## 4.0.0.beta.11 (skipped for RMS version parity)

## 4.0.0.beta.10 (2013-04-18)
* B-103674 - Add specs for testing blank rhoconnect app (run "rhoconnect" from any directory)
* B-103671 - RhoConnect JavaScript support added
* D-05019 - fixed path detection issue on windows for node.js
* D-05020 - fixed npm install on windows
* TK-185016 - Initial round of documentation for model/controller framework
* B-102914 - RhoConnect 4.0 migration guide
* TK-18647 - Add controller spec template into source adapter generation
* B-103294 - Update RMS install docs & RhoConnect install docs with RVM autolibs info

## 4.0.0.beta.9 (skipped for RMS version parity)

## 4.0.0.beta.8 (2013-04-02)
* B-101472 - Validate and fix JRuby-1.7.3 support (in Ruby 1.9.x compatibility (default mode))
* B-97594 - Model/Controller framework (All Sinatra extenstions, base model class)
* B-103017 - Model/Controller generators

## 4.0.0.beta.7 (skipped for RMS version parity)

## 4.0.0.beta.6 (2013-03-19)
* TK-182435 - Run platform validation in parallel (both nightly tests and release jobs)
* B-100239 - Implement QUERY rc_handler
* B-101530 - Re-work CUD, Search, BulkData routes rc_handlers

## 4.0.0.beta.5 (skipped for RMS version parity)

## 4.0.0.beta.4 (2013-03-06)
* B-97597 - Support multiple redis customizations, documentation & package installer updates
* Updated production stack to ruby-1.9.3-p392, redis-2.6.10, and nginx-1.3.13.

## 4.0.0.beta.3 (2013-02-19)
* B-97593 - Rhoconnect Controller Base class for Source Adapters
* B-98498 - Add specs to cover use-case with multiple Redis instances
* B-99420 - Increased minimum rack version to 1.5.2. Resolves the following security advisories: CVE-2013-0262, CVE-2013-0263
* B-03792 - Docs: Added a short section on multiple rhoconnect apps to the RhoConnect Deployment document.
* B-91170 - Docs: Created RhoConnect API chapters with API information taken from the RhoConnect development chapters.

## 4.0.0.beta.2 (2013-02-05)
* B-97601 - Refactor rhoconnect redis cli commands
* TK-173449 - Store support for multiple Redis instances
* B-97596 - re-factor Store code to provide uniform interface
* B-97840 - Documentation added for new rhoconnect cli options
  * New command line options are available here: http://edgedocs.rhomobile.com/rhoconnect/command-line#rhoconnect-command-line-interface
  * (See rhoconnect "start" and "restart" additions at end of the list)
* B-97934 - New "rhoconnect-client" extension build process.  See https://github.com/rhomobile/rhoconnect-client for instructions on how to build it.

## 4.0.0.beta.1 (2013-01-23)
* Implemented check for valid client documents (from now on any client doc not declared upfront is considered invalid and exception is thrown - thus, making calls like flush_data(*) invalid)
* Removed deprecation warning from SourceAdapter.initialize method (credential parameter is no longer supported)
* Update rhoconnect prod stack to ruby-1.9.3-p362 and latest redis (2.6.7) and nginx (1.3.10) releases.
* Unlocked 'fpm' gem to version >= 0.4.26 (release fixes broken rpm package build tools).
* Revert prod stack to ruby-1.9.3-p327 due to issue #7629 (https://bugs.ruby-lang.org/issues/7629?utm_source=rubyweekly&utm_medium=email)
* Update rhoconnect prod stack to ruby-1.9.3-p374
* Updated RhoConnect CLI: server is capable to start from any directory and accepts parameters (port, redis URL, and others)

## 3.4.5 (2013-05-14)
* TK-182435 - Run platform validation in parallel (both nightly tests and release jobs)
* D-04477 - Rack::Session::Cookie security warning printing on every http request
* B-106356 - Update nginx package to 1.4.1 (CVE-2013-2028)

## 3.4.4 (2013-02-27)
* Updated prod. stack to ruby-1.9.3-p392, redis-2.6.10, and nginx-1.3.13.

## 3.4.3 (2013-02-11)
* Updated rack gem to latest release with important security fixes. Locked version of 'connection_pool' gem.
* fixing 'rhoconnect spec' command in production env

## 3.4.2 (2012-11-8)
* fixed `rhoconnect redis-start` and `rhoconnect redis-restart` commands on windows
* D-04052 - Resque.after_fork hook wasn't initializing efficiently

## 3.4.1 (2012-11-6)
* D-04031 - `rhoconnect startbg` and `startdebug` commands not working on windows
* Locked win32-process gem to previous release (0.6.6) so Process.fork is available for
  `startbg` and `startdebug` commands.
* `rhoconnect update` command handles exceptions with useful error message

## 3.4.0 (2012-11-1)
* Let `pass_through` and `push_notify` be string or boolean
* B-90921 - `rhoconnect` command sets are now platform-specific
* D-03946 - Fixed `rhoconnect console` command on Windows
* B-91297 - Added defaults for api_token and push appname

## 3.4.0.rc5 (2012-10-26)
* Refactor 'Gemfile' in app generator template, add rhoconnect cmd 'update' to simplify upgrade legacy apps to latest gem

## 3.4.0.rc4 (2012-10-19)
* Updated production stack to ruby 1.9.3p286
* TK-04054 - fixed GCM push payload so 'data' field is passed to client

## 3.4.0.rc3 (2012-10-15)
* B-03380 - Added Google Cloud Messaging (GCM) support
* Filter added to simplecov report so spec files are not included
* D-01639 - Issues with Resque workers connection to Redis using connection pool
* D-01563 - `rake resque:work` fails with undefined ROOT_PATH

## 3.4.0.rc2 (2012-10-11)
* Removing Redis ConnectionPool from 1.8.7 (not supported there)
* Fixing GetClientDocs API with stats (incorrect return)

## 3.4.0.rc1 (2012-10-09)
* Add Redis connection pool as a default
* Add redis_timeout option
* Implement automatic user notify after push_objects, push_deletes
* B-03739 - Store re-design : implement diff by object - optimizes speed and Redis memory usage
* Bump nginx to v. 1.3.6, add http_stub_status_module and include "least_conn" directive to upstream section
* B-03303 - Move page_token and count into separate headers for easy access (to avoid heavy JSON parsing)

## 3.3.5 (2012-09-20)
* merge changes from master to fix broken bench script helper
* ZD-2866 - Issue with Apple Push when User has windows device as one of targeted devices 2 target devices

## 3.3.4 (2012-08-28)
* flush_zdata was not properly cleaning the related Redis storage (which led to incorrect CUD queue states)

## 3.3.3 (2012-08-21)
* allow selective bulk_sync source parameter to be sent as a comma-separated string

## 3.3.2 (2012-07-26)
* D-01571 - 'message' push param should be 'alert'

## 3.3.1 (2012-07-19)
* #33021139 - ping test page doesn't send sound parameter
* disable sqlite3 dependency by default so applications deploy on heroku without modification
* #28696971 - select which models to bulk sync
* cleaner layout on statistics page

## 3.3.1.beta4 (2012-07-17)
* #32952425 - rhoconnect startbg fails on windows

## 3.3.1.beta3 (2012-07-17)
* #32933277 - use explicit ~> 0.9.2.2 rake dependency
* integrate help content into pages of web console

## 3.3.1.beta2 (2012-07-09)
* #29806209 - Store re-design - implement persistent hashing
* #32389009 - Store re-design - optimize sync by computing diffs only for the requested number of objects (as specified by page_size)
* #26876157 - push: auth route added `/ans/login`
* #26892609 - push: queue support
* #31863031 - push: handle token post `device_push_type` attribute
* #32483159 - update web console to use RC v1 routes

## 3.3.1.beta1 (2012-06-29)
* #29796429 - use list to preserve bulk data sources order
* #29743645 - do not execute ping when platform is not configured
* #27198669 - REST API routes
* #27422451 - Create middleware to extract API token, current user, etc.
* #27198831 - Move API_TOKEN from params into the header
* #27198869 - Move CLIENT_ID from params into the header
* #30760809 - Bug move appserver to redis from memory and config settings
* #30732533 - dtach-install command fails
* Added `version` command to print current version
* #31161737 - PingJob handles missing user ids or users with no clients
* #31245585 - blob_attribs in bulk database missing overwrite flag

## 3.2.1 (2012-06-22)
* #30760809 - Bug move appserver to redis from memory and config settings
* #27555029 - support REDISTOGO_URL in addition to REDIS env vars as redis connection strings

## 3.2.0.final (2012-05-15)
* Release candidate

## 3.2.0.beta5 (2012-05-14)
* #29570143 - Disable Async Mode if RhoConnect app is started with Debugger

## 3.2.0.beta4 (2012-05-10)
* #29112553 - adding 'bundle exec' to shelled-out ruby commands
* #29050981 - replaced 'sh' to 'system' in rhoconnect commands to avoid Rake::DSL warnings
* #29411157 - removed custom eventmachine gem dependency
* #29413841 - removing 'thin' from JRuby config

## 3.2.0.beta3 (2012-05-04)
* #28922571 - loading feedback msg console
* #28923039 - add pre tags around json values (console)
* #28992255 - fixing windows background commands
* #29049115 - execute 'bundle install' automatically after the app is generated
* #29051271 - verbose incoming headers logging
* #29049681 - print warning if 'async-rack' dependency doesn't exist
* #29092021 - EventMachine segfaults on Windows with Ruby 1.9.3-p194

## 3.2.0.beta2 (2012-05-02)
* 28571961 fix jasmine tests
* #28496779 - remove rhoconnect_api.rb and all of its references
* #28563163 - bug fix : it should not be allowed to create a User with empty login
* #28528841 - Ping should process all clients and report cumulative error at the end
* Empty 'queue_updates' request should trigger processing of the CUD queue
* #28094895 - Zendesk ticket #2354: Bulk sync not updating sources table (fields 'last_inserted_size' and 'backend_refresh_time' now updated)
* #28855323 - Bulk Sync Associations from Zendesk ticket #2377
* #28576723 - dpkg lock error on Ubuntu install
* #28094895 - Zendesk ticket #2354: Bulk sync not updating sources table (fields 'last_inserted_size' and 'backend_refresh_time' now updated)
* #28865579 - Async dependencies are not properly initialized on Windows (need to add :mingw_19 to the list of platforms in Gemfile)
* Rhoconnect production stack updated to latest stable version of ruby, redis, and nginx: ruby-1.9.3-p194, redis-2.4.12, nginx-1.2.0.

## 3.2.0.beta1 (2012-04-20)
* Rhoconnect commands (replacement for rake tasks)
* Async framework is introduced for rubies 1.9.x (no 1.8.7 or JRuby support)
* 26384435 - Rhoconnect Linux installer should use ruby-1.9.3-p125 as a default ruby
* 27612327 - Bulk Sync Not Returning Errors from Zendesk ticket #2336
* Rhoconnect production stack is updated for full support of async framework (nginx as reverse proxy server, thin app server)
* #28219647 - Schema Change Error from Zendesk ticket #2353
* #28328057 - Feature Request: Adding a Bulk Data Job after_perform hook from Zendesk ticket #2367
* #28330213 - Implementing fast_insert/update/delete API
* #27051649 - Rhoconnect Console is re-worked using Twitter.Bootstrap

## 3.1.2 (2012-04-02)
* #19297819 - Refactor server middleware loading to be static
* #25292219 - Ensure that Store.get_zdata always returns valid array (even if it is empty)
* #26310661 - No test_search
* #26868157 - bug in install.sh in rhoconnect installer
* #26384435 - Replace in rhoconnect installer Ruby Enterprise by latest stable Ruby 1.9.3
* #27184633 - Fixing error with recursive loading of application.rb in ruby-1.8.7 and ree
* use redis 2.4.10 by default

## 3.1.1 (2012-02-07)
* Fix Zendesk issue: Rack 1.4.1 and Sinatra 1.3.2 produce 502 error with Heroku deployment (tickets 2147, 2155, 2153)

## 3.1.0 (2012-01-31)
* #23977723 - Bug fix (Rspec examples fails for both Ruby 1.8.7 and  ree-2011.12 (p357))
* #23982399 - Add to RhoConnect installer support for ree 2012.01
* Support of latest versions of Ruby (Ruby 1.8.7 and ree-2011.12 (p357), Jruby-1.6.5.1) on Linux and Mac OS X platforms

## 3.1.0.beta2 (2012-01-24)
* #21859561 - bug fix (Sync With Sugar CE Brings No Records and Generates An Error from Zendesk ticket #1871)
* #22399583 - bug fix (Creates are happening multiple times for the same data from Zendesk ticket #1964)
* #22765085 - 1.9.3 Ruby support - all platforms (Mac,Linux,Windows)
* #22801803 - support rack 1.4 (bundle dependency '~> 1.4.1')
* #22965211 - bug fix (startbg, startdebug tasks do not work with Ruby 1.9.x)
* #23100341 - bug fix (large JSON input is lost in rack, Ruby 1.9.x)
* #23634587 - bug fix (related data models not getting updated from Zendesk ticket #2098)
* #23641249 - Update Rhoconnect .NET sample with final code
* #23625065 - Bug fix (Installing Rhoconnect from Zendesk ticket #2101)
* #23641103 - .NET plugin needs to have an ability to be partitioned by app
* #23641329 - JAVA plugin needs to have an ability to return "app" partition
* #23638123 - Checking for duplicate creates from Zendesk ticket #2097
* #21237229 - Docs for rhoconnect-benchmark commands
* #23767161 - Bug fix (java-plugin doc fails to index with indextank)
* Added code coverage for Ruby 1.9 (gem 'simplecov')

## 3.1.0.beta1 (2011-12-31)
* #20396499 - saving rhoconnect-benchmark results into the file
* #21630639 - rhoconnect-benchmark post-processing (GRUFF png images and EXCEL spreadsheets generation)
* #21363347 - rhoconnect-benchmark - support for varying the number of concurrent clients and payload, distributed AWS clients
* #20151369 - rhoconnect-benchmark command
* #21187827 - support for built-in internal adapters
* #22208995 - AWS Cloud Formation deployment guidelines docs
* #22209097 - Conflict Resolution framework for simultaneous CUD operations

## 3.0.6 (2011-11-15)
* #20022889 - support for GET/POST /api/application routes
* #20609683 - support 'append' parameter in 'set_db_doc' REST API
* #20910767 - fix for params modification in before filter (#1802,#1804) and fixing incorrect blob create spec
* #20917129 - adding spec for checking 'Cache-Control:no-cache' and 'Pragma:no-cache' response headers

## 3.0.5 (2011-10-21)
* use redis 2.4 by default
* #17447481 - auto-renewal of expired C2DM tokens
* #19723593 - re-creating Client if clientregister call is made with unknown client id

## 3.0.4 (2011-10-13)
* #19675957 - fixing broken task :set_admin_password

## 3.0.3 (2011-10-13)
* #19304885 - fixing race condition in get_lock (lock is released between setnx and get calls)
* #18508155 - on failed syncs allow the user to retry it up to pre-defined number of times (another approach)

## 3.0.2 (2011-10-05)
* #19143845 - support sinatra 1.3.x

## 3.0.1 (2011-10-04)
* fix to lock in sinatra 1.2.7

## 3.0.0 (2011-09-30)
* #18888077 - implement Redis transactions optimization for push_objects and push_deletes
* added 2 rake tasks (build:rpm and build:deb) to generate packaged software for popular linux servers
  (CentOS/Ubuntu). The package includes ruby enterprise, redis and nginx servers, passenger,
  and rhoconnect gem with all dependencies
* #19116273 - created new redis:startbg task for Rhostudio

## 3.0.0.rc1 (2011-09-27)
* load sqlite3 gem on demand, fixes issue with generator requiring it
* #18934311 - create :startbg task for Rhostudio

## 3.0.0.beta3 (2011-09-23)
* #18672811 - edge case produces race condition which leads to corruption of Store data
* #18508155 - on failed syncs allow the user to retry it up to pre-defined number of times

## 3.0.0.beta2 (2011-09-14)
* #17830175 - moved SystemTimer in application's Gemfile so rhoconnect gem isn't specific
* #13303895 - Generating a new source with 'rhosync source <name>' deletes sections in settings.yml
* #10313437 - support source settings per environment

## 3.0.0.beta1 (2011-09-01)
* #1018 user delete now iterates through user sources and deletes data in redis
* #11102931 ping api accepts vibrate string and int
* #7197617 test spec helpers support pass through
* #11944605 implemented pass through feature
* #4397476 wrapped login/logoff around cud spec helpers
* backtrace logging in source adapter method exceptions
* returning string in authenticate instead of true sets the current user login name (Useful for OAuth2)
* #11904353 - fixed broken 'rake console' task, added new 'rhosync' namespace: 'rake rhosync:console'
* #12105115 - removed unnecessary log4r dependency
* added bundler to manage gem's dependencies, migrated from rspec1 to rspec2
* #5687948 - fixed issue "iPhone push specs failed"
* use redis 2.2.14 by default
* added SystemTimer gem dependency (used only on posix systems)
* #13616807 - Rake task spec:all fails for enterprise ruby (ree)
* #13776713 - Rake -v 0.9.0 breaks rhosync rake tasks
* #14514773 - REST API push_object, push_deletes :md_size count fix
* #5687948  - fixed issue "iPhone push specs failed"
* #12854737 - string vs. symbol problem in ruby 1.9 model.rb (contribute to ruby 1.9 support)
* #11692191 - ruby 1.9 support
* #2020980  - Test on JRuby. Code reworked to fully support JRuby platform.
* #14087743 - Merging the /login and /get_api_token methods.
* #14713569 - Moving all Server REST API calls into namespaces.
* #14284841 - Merge ruby_19 branch into master
* #14784949 - Suppress rake -v 0.9.2 warning messages while running tasks.
* #3174947  - RESTful routes for client management
* #14968209 - Generated Specs are failing on 2nd generated source
* #15270505 - sqlite3 is not listed as a dependency of rhosync gem (3.0.0)
* #15143911 - Schema Changed message from Zendesk ticket #1035 (merge from branch 2-1-stable 2.1.9)
* #14950665 - Benchmark application and libraries: rework REST calls to match new API restful routes.
* #14860303 - In bench tests x_domain_session_wrapper middleware not working under ruby 1.9.2.
* #15615327 - Rhoconnect migration
* #15730829 - added migration guidelines doc
* #14286067 - jruby rhosync:start : console doesn't work
* #14286249 - jruby WAR file deployed , some of the links are broken in console window, should use the relative paths
* #14285867 - jruby rhosync:start should have run with dtach
* #17526603 - implement clientreset support for specified sources
* #16628143 - implement 'ping' for multiple users at once in REST API
* #18003071 - enhancing console to support multi-user ping
* #10313437 - source settings per environment (also applied to dynamic adapters)
* #18356697 - store lock is never released (bug fix)

## 2.1.10 (2011-08-17)
* #16001227 - raise exceptions on c2dm errors
* #1018 - delete read state for user as well

## 2.1.9 (2011-07-01)
* #15143911 - Fix for incident schema changed message

## 2.1.8 (2011-06-29)
* #1018 - added functionality to delete user source data on user delete
* updated to rake 0.9.2
* #14911833 - Add support for rolling back updates on sync errors

## 2.1.7 (2011-05-31)
* #14021681 - check for client on client_sync class methods
* #14082861 - expose Store.lock timeout to high-level functions
* #14082589 - fixed source loading so a unique instance is loaded
* #14124195 - concurrency issue under load for same user via push_objects api
* #14511763 - added global options `raise_on_expired_lock` (true/false) and `lock_duration` (sec) settings

## 2.1.6 (2011-05-25)
* #13830841 - fixed issue where current_user.login doesn't match @source.user_id

## 2.1.5 (2011-05-24)
* #13578473 - fixed "undefined method `user_id' for nil:NilClass" error in server.rb

## 2.1.4 (2011-05-20)
* #13354369 - bug fix "rhosync bootstrap process shouldn't store sources in redis"

## 2.1.3 (2011-05-05)
* #4398193 - ping should only send push messages to unique device pin list
* #13022667 - settings.yml doesn't work for setting external Redis instances

## 2.1.2 (2011-03-18)
* Use server-dir/redis.conf if not found at RedisRunner.prefix (via artemk)
* #8471337 - switch client user if it is not equal to current_user
* Upgrade rest-client dependency which includes cookie escape fix
* #10097347 - generate cryptographically secure secret key by default
* Fixed 'application/json; charset=UTF-8' content handling in the server before filter
* #11017509 - fixed sinatra 1.2 incompatibility with url() helper
* #4569337 - use redis 2.2.2 by default
* #4398193 - ping should only send push messages to unique device pin list

## 2.1.1 (2011-01-04)
* #7679395 - added support for gzipped bulk data files
* #8167507 - fixed typo in console login page
* #7025387 - customizable redis.conf for windows

## 2.1.0
* #4302316 - don't allow set blank admin password
* #5672322 - stats for user count
* #5672316 - stats for device count
* #5717916 - stats api call
* #5821277 - http stats by source not showing
* #5899454 - move lock prefix to beginning so we don't return stats keys with it
* #5822966 - bulk sync data file cannot handle space in the username
* #6450519 - blob sync resend_page doesn't send metadata
* #4646791 - cryptic error message if client exists, but source name is bogus
* #6827511 - fill in schema column in bulk sync file sources table
* #4490679 - support schema method in source adapter (runtime schema for bulk data)
* #6573429 - if schema changed in any adapter, invalidate bulk data file
* #7034095 - don't ping device if device_pin is empty or nil
* #7089047 - fixed application.rb template store_blob method
* #7055889 - fixed schema tables should have 'object' primary key
* #6011821 - try to make bin_dir on redis:install and dtach:install

## 2.0.9 (2010-10-14)
* #5154725 - stats framework
* #5013521 - new web interface style
* #5615901 - fixing hsqldata bulk data file format
* #5672140 - http request timings middleware
* #5672148 - source adapter execution timings
* #5620719 - session secret override didn't work
* #3713049 - added support for Android Cloud to Device Messaging

## 2.0.8 (2010-10-08)
* #5246936 - changed settings.yml-belongs_to format to use array instead of hash
* #5578580 - allow Store.db to accept an existing redis object (useful for overriding redis settings)

## 2.0.7 (2010-09-13)
* #4893692 - fixed infinite search loop
* search properly handles multiple page results

## 2.0.6 (2010-08-25)
* #4701421 - dbfile url has junk characters
* #4731763 - support 'apple' device type, deprecate 'iphone' device type
* #4763532 - sound was missing from BB pap message

## 2.0.5 (2010-08-10)
* #4650808 - use ENV['RHOSYNC_LICENSE'] if it exists
* #4650820 - added UI checkbox for direct api calls

## 2.0.4 (2010-08-04)
* #3624650 - support redis-rb ~>2.0.0
* #4480303 - support connection to redis uri, if ENV[REDIS_URL] exists
* #4565808 - support direct ruby api calls

## 2.0.3 (2010-07-21)
* #4379293 - don't fail ping job if device type is nil or empty, just skip the device

## 2.0.2 (2010-07-16)
* #4236653 - add confirmation to console and task reset
* #3582679 - added rhosync:set_admin_password task

## 2.0.1 (2010-07-01)
* #4124559 - rake redis:install fails due to redis build changes, require 1.3.12 for now
* #4094373 - default task is now rhosync:spec

## 2.0.0.rc2, 2.0.0 (2010-06-28)
* #4040573 - sqlite3-ruby v1.3.0 breaks bulk data tests, require ~>1.2.5 for now

## 2.0.0.rc1
* dupe tag of 2.0.0.beta13

## 2.0.0.beta13
* #3417862 - namespacing issue with HashWithIndifferentAccess

## 2.0.0.beta12
* #3851464 - log every error in client post parsing
* #3795105 - store associations in sources table for bulk data

## 2.0.0.beta11
* #3850478 - fix hardcoded hsqldata.jar path

## 2.0.0.beta10
* #3662891 - adding rhosync:flushdb rake task
* #3742919 - fixing sources json structure according to http://wiki.rhomobile.com/index.php/Rhom#Source_Configuration_Protocol
* #3740205 - changed default admin user to 'rhoadmin'

## 2.0.0.beta9
* #3565139 - return better error message if client/source is unknown
* #3616601 - added blob_attribs to bulk data job file
* #3576126 - added expire_bulk_data source adapter method
* #3576151 - trigger new bulk data job if any relevant dbfiles are missing
* #3707791 - fixing ROOT_PATH problem on windows

## 2.0.0.beta8
* #3685476 - CGI escape api cookies

## 2.0.0.beta7
* #3651932 - support redis:* tasks on windows and linux/mac
* #3663335 - don't need ENV['PWD'] in tasks.rb

## 2.0.0.beta6
* no new changes, rubygems.org upload failed for 2.0.0.beta5

## 2.0.0.beta5
* #3628036 - support loading generator from gem

## 2.0.0.beta4
* #3316030 - added rspec test framework
* #3557341 - create new bulk data instance if the file is missing
* #3415335 - support fixed schema models
* #3582235 - report error if client-posted json doesn't parse (instead of crashing server)

## 2.0.0.beta3
* #3316030 - added source adapter spec helper + infrastructure
* #3475519 - return exception string on 401 / 500 login errors
* #3513037 - re-animated bulk sync feature
* #3511533 - added stash_result source adapter utility - useful for huge datasets
* #3539092 - added rake rhosync:web task

## 2.0.0.beta2
* #3416343 - unify rake tasks to work on windows & Mac OS / *nix

## 2.0.0.beta1
* New implementation of RhoSync using redis storage engine
* Support for modular routes (console & resque frontend optional)
* Bulk Data synchronization
* REST api for server management
