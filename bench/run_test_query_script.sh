#! /bin/sh

timestamp_postfix=$(date +%Y_%m_%d_%H%M%S)
test_label=query_bench_$timestamp_postfix
if [ $# -gt 0 ] ; then
    test_label=$1
fi
server='default'
if [ $# -gt 1 ] ; then
    server=$2
fi

n_iterations=10

# setup the benchmark directory structure
ruby prepare_bench $test_label query_bench_$timestamp_postfix "1 2 3 5 10"

# simulate various number of simultaneous clients
for n_threads in 1 2 3 5 10
do
	# simulate variaous number of data records
	for payload in 1 5 10 50 100 250 500
	do
		result_filename=./bench_results/query_bench_$timestamp_postfix/raw_data/query_bench_result.$payload
		ruby bench start 'scripts/test_query_script.rb' 'rhoadmin' '' $server $result_filename $n_threads $n_iterations $payload
	done
done

# once benchmark is finished - process the results
ruby ./lib/bench/bench_result_processor.rb ./bench_results/query_bench_$timestamp_postfix/raw_data ./bench_results/query_bench_$timestamp_postfix/images
