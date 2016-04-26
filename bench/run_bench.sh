#!/bin/bash
# 
# Add the following line to crontab to execute benchmarks as a cron job on workdays at 1AM
#
# 0 1 * * 1-5 /Users/rhomobile/workspace/rhoconnect/bench/run_bench.sh
#

# ALL log messages go to '/tmp/bench.log' file 
echo '' > /tmp/bench.log

if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"  >> /tmp/bench.log
  exit
fi

cd '../'
RHOCONNECT_HOME=`pwd`

# echo "RhoConnect code already up-to-date." | tee -a /tmp/bench.log
echo "Pull rhoconnect code from remote repository ..." | tee -a /tmp/bench.log
git reset --hard HEAD | tee -a /tmp/bench.log 2>&1
git pull origin master | tee -a /tmp/bench.log 2>&1
echo '' | tee -a /tmp/bench.log

echo 'Flush Redis DB' | tee -a /tmp/bench.log
redis-cli flushdb > /dev/null

# Run benchmarks for ruby 1.8.7, ree, 1.9.2, and 1.9.3
#  TODO: 'jruby'
for ruby in '1.9.3'
do
  rvm use $ruby > /dev/null
  ruby_version=$(rvm current)
  echo "Running benchmarks for $ruby_version ..." | tee -a /tmp/bench.log
  echo "" | tee -a /tmp/bench.log

  ruby ./bench/bench_runner.rb $RHOCONNECT_HOME /tmp/bench.log
  if (($?)) ; then echo "Benchmarks for $ruby_version failed"; exit 1; fi
done


