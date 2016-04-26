RhoConnect App Integration Server
-------------------------------------------------------------
RhoConnect is an app integration server which keeps enterprise data current and available on users’ devices.

Development Prerequisites
-------------------------------------------------------------
You will need to install the following in order to run the RhoConnect specs.

* QT: <http://qt.nokia.com/downloads>
* RVM: <https://rvm.io/> or RB-env: <https://github.com/sstephenson/rbenv> with Ruby 1.9.3p194+ installed
* Bundler: <http://gembundler.com/>
* Redis: <http://redis.io>

Running Tests
-------------------------------------------------------------

* Install dependencies

```
$ bundle install
```

* Start redis (assumes it is installed in /usr/local/bin)

```
$ rake redis:start
```

* Run RhoConnect specs

```
$ rake spec
```

You will see a lot of output including backtraces as negative tests produce exceptions that print to stdout.  This is normal.  At the end you should see something like the following:

<pre>
Finished in 47.47 seconds
543 examples, 0 failures
...
Running Jasmine specs...
.........................................
PASS: 41 tests, 0 failures, 0.05 secs.
</pre>

If you have 0 failures, everything is good!

Test Layout
-------------------------------------------------------------
RhoConnect uses the [RSpec](https://www.relishapp.com/rspec/) framework to implement tests.  All tests are located in the `spec/` directory.  Tests use the following file naming convention: `classname_spec.rb` where `classname` is the class under test (i.e. `server_spec.rb` tests the `Server` class).

Resources
-------------------------------------------------------------
  * RhoConnect:	<http://docs.rhomobile.com/rhoconnect/introduction>
  * Tutorial:   <http://docs.rhomobile.com/rhoconnect/tutorial> 
