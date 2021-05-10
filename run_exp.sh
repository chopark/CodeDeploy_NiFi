#!/bin/bash
## USAGE
## ./run_exp.sh (sleep time) (the number of target edge group)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (the number of target edge group): 1, 2, 3, ..."

SHELL=`basename "$0"`
EXPECTED_ARGS=5

if [ $# -lt $EXPECTED_ARGS ]; then
    echo "$SHELL: USAGE: $SHELL (interactive) (sleep time) (target groups) (number of nodes per group) (number of wms to skip for analysis)"
    echo "$SHELL: e.g. (interactive): true,false"
    echo "$SHELL: e.g. (sleep time): 60s, 10m, 1h"
    echo "$SHELL: e.g. (target groups): 1, 2, 3, ..."
    echo "$SHELL: e.g. (number of nodes per group): 4,8, ..."
    echo "$SHELL: e.g. (number of wms to skip during log analysis) 4"
    exit 1
fi

# Directories
HOME="/home/ubuntu"
DEFAULT_HOME="/home/ubuntu"
NIFI_HOME="$HOME/jarvis_nifi"
NIFI_LOG="$NIFI_HOME/logs"
NIFI_CUSTOM_LOG="$NIFI_HOME/nifi_custom.cfg"
NIFI_SCRIPT="$NIFI_HOME/scripts"
NIFI_CODEDEPLOY="$DEFAULT_HOME/CodeDeploy_NiFi"
NIFI_BIN="$NIFI_HOME/bin"
NIFI_RESULTS="$NIFI_HOME/results"
MINIFI_DIR="$DEFAULT_HOME/minifi"
MINIFI_HOME="$MINIFI_DIR/minifi-0.5.0"
MINIFI_BIN="$MINIFI_HOME/bin"
MINIFI_SCRIPT="$MINIFI_DIR/scripts"
MINIFI_LOGS_LOCATION="$HOME/temp-jarvis/minifi_logs"

#Variables
FINAL_QUEUE_ID="ec73aa70-0174-1000-f201-66b549d134a8"
#FINAL_QUEUE_ID="e698454e-0174-1000-395e-0ac12663fd63"
LOG_PROCESSOR_ID="d02bb153-016c-1000-3bed-7ffc10e019d1"
#LOG_PROCESSOR_ID="e698247f-0174-1000-1c40-f3a6ff2da6c0"
#time_limit=`date "+%H%M" -d "+1 min"`

# change this to use in other instances...
cmd_num=0
interactive=$1
target_groups=$3
nodes_per_group=$4
total_nodes=$(($target_groups*$nodes_per_group))

if [ "$interactive" != "true" ]; then
	ht_disabled="n"
else
	read -p "Is hyperthreading disabled?(y/n) " ht_disabled	
fi

if [ "$ht_disabled" != "y" ]; then
	bash $NIFI_SCRIPT/disable_hyperthreading.sh
fi

if [ "$interactive" != "true" ]; then
	net_bw_set="y"
else
	read -p "Is network bandwidth correctly set?(y/n) " net_bw_set
fi

if [ "$net_bw_set" != "y" ]; then
	echo "set network bw correctly before continuing"
	exit 1	
fi

java -version
version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ "$version" != *"1.8.0_222"* ]]; then
	cd $NIFI_CODEDEPLOY/jdk
	bash reinstall-jdk.sh 
	cd $NIFI_CODEDEPLOY
fi

# Change the ownership to prevent the error
sudo chown -R ubuntu:ubuntu $NIFI_HOME

# Set edge id
./set_edgeId.sh

# Set config files per group
./set_conf.sh $target_groups

# Change the nifi custom config file
sudo sed -i "s~numEdges\"\: \"[[:digit:]]\+\"~numEdges\"\: \"$total_nodes\"~g" $NIFI_CUSTOM_LOG

# Start NiFi
sudo sh $DEFAULT_HOME/CodeDeploy_NiFi/restart_nifi.sh

# Get your current server ip.
IP=`hostname -i`

echo "$SHELL: FlowFiles will be parsed with your NiFi IP($IP)"
echo "$SHELL: Checking flowFilesQueued...";echo;
# Parse flowFilesQueued.
FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;

# If the final queue in our dataflow contains any pending flowfiles to be processed, clean it.
while [ -z "$FLOWFILESQUEUED" ]; do
    sleep 5s
    FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
    echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;
done
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;

echo "$SHELL: NiFi ready, start MiNiFi."
# Restart MiNiFi
## Uncomment this to start instances all at once
#aws ssm send-command --targets "Key=tag:type,Values=edge" \
#--document-name "AWS-RunShellScript" \
#--comment "start MiNiFi" \
#--parameters commands="sudo sh $HOME/scripts/start_minifi.sh" \
#--output text

if [ $# -ge $(($EXPECTED_ARGS+1)) ]; then
    NEXT_ARG_NUM_AFTER_EXPECTED=$(($EXPECTED_ARGS+1))
    NEXT_NEXT_ARG_NUM_AFTER_EXPECTED=$(($EXPECTED_ARGS+2))
    cpu1=${!NEXT_ARG_NUM_AFTER_EXPECTED}
    possibleDelay=${!NEXT_NEXT_ARG_NUM_AFTER_EXPECTED}
    if [[ $possibleDelay == "now" ]]; then
	time_limit="now"
    else
        time_limit=`date "+%H%M" -d "+1 min"`
        if [ $# -ge $(($EXPECTED_ARGS+2)) ]; then
            NEXT_ARG_NUM_AFTER_EXPECTED=$(($EXPECTED_ARGS+2))
            cpu2=${!NEXT_ARG_NUM_AFTER_EXPECTED}
            time_limit2=`date "+%H%M" -d "+3 min"`
        fi
    
        if [ $# -ge $(($EXPECTED_ARGS+3)) ]; then
            NEXT_ARG_NUM_AFTER_EXPECTED=$(($EXPECTED_ARGS+3))
            cpu3=${!NEXT_ARG_NUM_AFTER_EXPECTED}
            time_limit3=`date "+%H%M" -d "+5 min"`
        fi
    fi 
    
    MiNiFi_command="$cpu1 $time_limit $cpu2 $time_limit2 $cpu3 $time_limit3"
    MiNiFi_command="$cpu1 $time_limit $cpu2 $time_limit2 $cpu3 $time_limit3"

    while [ $cmd_num -lt $target_groups ]; do
        #aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
        aws ssm send-command --targets "Key=tag:deploy,Values=$cmd_num" \
        --document-name "AWS-RunShellScript" \
        --comment "start MiNiFi" \
        --parameters commands="sudo sh $DEFAULT_HOME/scripts/start_minifi.sh $MiNiFi_command" \
        --max-concurrency 100% \
        --output text
        cmd_num=$(($cmd_num+1))
    done
else
    while [ $cmd_num -lt $target_groups ]; do
        #aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
        aws ssm send-command --targets "Key=tag:deploy,Values=$cmd_num" \
        --document-name "AWS-RunShellScript" \
        --comment "start MiNiFi" \
        --parameters commands="sudo sh $DEFAULT_HOME/scripts/start_minifi.sh" \
        --max-concurrency 100% \
        --output text
        cmd_num=$(($cmd_num+1))
    done
fi

rm cpu.csv
cpustat -n 1 >> cpu.csv &
CPUSTAT_PID=$!

current_time_now=$(date)
echo "Current time: $current_time_now"
echo "$SHELL: Sleeping $2..."
# Sleep as input time.
sleep $2

# Stop MiNiFi
cmd_num=0

## Uncomment this to stop instances all at once
#aws ssm send-command --targets "Key=tag:type,Values=edge" \
#--document-name "AWS-RunShellScript" \
#--comment "stop MiNiFi" \
#--parameters commands="sudo sh /home/ubuntu/scripts/stop_minifi.sh" \
#--output text
#
echo "cpustat PID is: $CPUSTAT_PID"
#pkill $CPUSTAT_PID
sudo kill -9 $CPUSTAT_PID

############Older command######################
#--parameters commands="sudo $MINIFI_BIN/minifi.sh stop" \
############Older command######################
while [ $cmd_num -lt $target_groups ]; do
    #aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
    aws ssm send-command --targets "Key=tag:deploy,Values=$cmd_num" \
    --document-name "AWS-RunShellScript" \
    --comment "stop MiNiFi" \
    --parameters commands="sudo sh $DEFAULT_HOME/scripts/stop_minifi.sh" \
    --max-concurrency 100% \
    --output text
    cmd_num=$(($cmd_num+1))
done
#read -p "Press enter to continue after all minifi stopped"

echo "$SHELL: Checking flowFilesQueued...";echo;
# Parse flowFilesQueued.
FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;

# If the final queue in our dataflow contains any pending flowfiles to be processed, clean it.
# After text '--data-binary', calling $LOG_PROCESSOR_ID did not work for some reason. So I put the ID value instead of $LOG_PROCESSOR_ID.
if [ ! -z "$FLOWFILESQUEUED" -a "$FLOWFILESQUEUED" != 0 ]; then
    echo "$SHELL: Cleaning up pending flowfiles..."

    curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary "{\"revision\":{\"clientId\":\"$LOG_PROCESSOR_ID\",\"version\":0},\"component\":{\"id\":\"$LOG_PROCESSOR_ID\",\"state\":\"RUNNING\"}}";echo; echo;
    
    while [ $FLOWFILESQUEUED != 0 ] ; do
        sleep 2s
        FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
        echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;
    done
    
    echo; curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary "{\"revision\":{\"clientId\":\"$LOG_PROCESSOR_ID\",\"version\":0},\"component\":{\"id\":\"$LOG_PROCESSOR_ID\",\"state\":\"STOPPED\"}}";echo
fi  

FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"

# Stop NiFi
#echo; read -p "$SHELL: Do you want to stop NiFi server? [y/n]" -n 1 -r
#echo; read -p "$SHELL: Do you want to stop NiFi server? [y/n]"
#if [[ $REPLY =~ ^[Yy]$ ]]
if true;
then
    echo; echo "$SHELL: Stop running Nifi instance..."
    sudo sh $NIFI_BIN/nifi.sh stop
fi

sudo chown -R ubuntu:ubuntu $NIFI_HOME

# If there is old log_cat file, delete it.
if [ -f "$NIFI_LOG/log_cat" ]; then
    echo "$SHELL: Remove previous log_cat..."; echo;
   rm $NIFI_LOG/log_cat
fi

# Parse the log and show the result.
echo "$SHELL: Parsing the NiFi logs..."
cat $NIFI_LOG/nifi-app* >> $NIFI_LOG/log_cat

echo "Collecting minifi logs all data source nodes"
bash $NIFI_SCRIPT/get_minifi_logs.sh

echo "Processing the logs to get throughput"
total_nodes=$(($target_groups*$nodes_per_group))
python3.5 process_nifi_minifi_logs.py $NIFI_LOG/log_cat $total_nodes $MINIFI_LOGS_LOCATION $5

# Calculate second
if [[ $2 == *"m"* ]]; then
	num=`echo "${1//m}"`
	runtime_second=$(($num*60))
elif [[ $2 == *"s"* ]]; then
	num=`echo "${1//s}"`
	runtime_second=$num
fi
runtime_second=$(($runtime_second-15))
python3.5 get_thruput_cloud_merging_v1.py $NIFI_LOG/log_cat $runtime_second > $NIFI_LOG/temp

echo; echo "RESULT"; echo "------------------------------------------"
tail -n 16 $NIFI_LOG/temp; echo "------------------------------------------"; echo

./get_mid_cpu.sh test

# Ask if you want to save it.
#echo;read -p "$SHELL: Do you want to save this log? [y/n]"
SAVE_REPLY="n"
#if [[ ! $REPLY =~ ^[Yy]$ ]]; then
if [[ ! $SAVE_REPLY =~ ^[Yy]$ ]]; then
    echo;echo "$SHELL: Done."
    exit 1
fi

# Save as
while true; do
    echo; read -p "$SHELL: Type a filename: " file_name
    if [ "$file_name" == "" ]; then
        echo "$SHELL: Please name it with non-empty string."
    elif [ -f "$NIFI_RESULTS/$file_name" ]; then
        echo "$SHELL: File exist. Please name it with other name."
    else
        break
    fi
done
cp $NIFI_LOG/temp $NIFI_RESULTS/$file_name
echo "$SHELL: Saving a file as $NIFI_RESULTS/$file_name"

echo;echo "$SHELL: Done."
