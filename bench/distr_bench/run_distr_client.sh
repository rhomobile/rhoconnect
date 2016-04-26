#! /bin/sh
test_label=$1
server=$2
n_iterations=$3
payload=$4
adapter_name=$5

RACK_ENV=production
export RACK_ENV

sync_key="${test_label}_$payload"
n_threads=1
ruby distr_bench start '../scripts/test_query_script.rb' 'rhoadmin' '' $server $sync_key $n_threads $n_iterations $payload 0 $adapter_name
