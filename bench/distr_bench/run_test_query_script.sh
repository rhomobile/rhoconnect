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



clients[0]=ec2-107-20-56-25.compute-1.amazonaws.com
clients[1]=ec2-67-202-35-54.compute-1.amazonaws.com
clients[2]=ec2-50-17-104-6.compute-1.amazonaws.com
clients[3]=ec2-204-236-222-92.compute-1.amazonaws.com
clients[4]=ec2-50-17-92-146.compute-1.amazonaws.com
clients[5]=ec2-107-22-124-158.compute-1.amazonaws.com
clients[6]=ec2-184-72-165-204.compute-1.amazonaws.com
clients[7]=ec2-107-20-41-32.compute-1.amazonaws.com
clients[8]=ec2-107-22-35-238.compute-1.amazonaws.com
clients[9]=ec2-50-16-180-250.compute-1.amazonaws.com

n_iterations=25
current_path=`pwd`

# setup the benchmark directory structure
ruby ../prepare_bench "$test_label" query_bench_$timestamp_postfix "1 2 3 5 10"

# simulate variaous number of data records
for n_clients in 1 2 3 5 10
do
	for payload in 1 5 10 50 100 250 500
	do
		result_filename=./bench_results/query_bench_$timestamp_postfix/raw_data/query_bench_result.$payload
		sync_key=sync_${timestamp_postfix}
#		for ((  i = 0 ;  i < $n_clients;  i++  ))
#		do
#			ssh -i /tmp/EC2-inst.pem -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ec2-user@${clients[$i]} "cd /opt/rhoconnect/bench/distr_bench; ./run_distr_client.sh $sync_key $server $n_iterations $payload 1>/dev/null" &
#			started_pid=$!
#			echo $started_pid
#		done
	
		# start main script
		ruby distr_bench_main $sync_key $payload $n_clients $result_filename $server
		sleep 10	
	done
done

# once benchmark is finished - process the results
ruby ../lib/bench/bench_result_processor.rb ./bench_results/query_bench_$timestamp_postfix/raw_data ./bench_results/query_bench_$timestamp_postfix/images
