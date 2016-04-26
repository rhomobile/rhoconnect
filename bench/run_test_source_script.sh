#! /bin/sh

timestamp_postfix=$(date +%Y_%m_%d_%H%M%S)
n_iterations=100
#server='http://rhohub-mzverev-c7ca8de3.rhosync.com/api/application'
server='default'

# setup the benchmark directory structure
ruby prepare_bench 'Rhoconnect SOURCE API benchmark' source_bench_$timestamp_postfix "1 2 5 10 15 20"

# simulate various number of simultaneous clients
for n_threads in 1 2 5 10 15 20
do
	result_filename=./bench_results/source_bench_$timestamp_postfix/raw_data/source_bench_result.test
	ruby bench start 'scripts/test_source_script.rb' 'rhoadmin' '' $server $result_filename $n_threads $n_iterations
done

# once benchmark is finished - process the results
ruby ./lib/bench/bench_result_processor.rb ./bench_results/source_bench_$timestamp_postfix/raw_data ./bench_results/source_bench_$timestamp_postfix/images


