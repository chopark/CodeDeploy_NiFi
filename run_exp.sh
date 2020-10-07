#!/bin/bash
## USAGE
## ./run_exp.sh (sleep time) (the number of target edge group)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (the number of target edge group): 1, 2, 3, ..."

SHELL=`basename "$0"`

if [ $# != 2 ]; then
    echo "$SHELL: USAGE: $SHELL (sleep time) (target groups)"
    echo "$SHELL: e.g. (sleep time): 60s, 10m, 1h"
    echo "$SHELL: e.g. (target groups): 1, 2, 3, ..."
    exit 1
fi

# Directories
HOME="/home/ubuntu"
DEFAULT_HOME="/home/ubuntu"
NIFI_HOME="$HOME/jarvis-nifi"
NIFI_LOG="$NIFI_HOME/logs"
NIFI_SCRIPT="$NIFI_HOME/scripts"
NIFI_BIN="$NIFI_HOME/bin"
NIFI_RESULTS="$NIFI_HOME/results"
MINIFI_DIR="$DEFAULT_HOME/minifi"
MINIFI_HOME="$MINIFI_DIR/minifi-0.5.0"
MINIFI_BIN="$MINIFI_HOME/bin"
MINIFI_SCRIPT="$MINIFI_DIR/scripts"

#Variables
FINAL_QUEUE_ID="ec73aa70-0174-1000-f201-66b549d134a8"
#FINAL_QUEUE_ID="e698454e-0174-1000-395e-0ac12663fd63"
LOG_PROCESSOR_ID="d02bb153-016c-1000-3bed-7ffc10e019d1"
#LOG_PROCESSOR_ID="e698247f-0174-1000-1c40-f3a6ff2da6c0"
#time_limit=`date "+%H%M" -d "+1 min"`

# change this to use in other instances...
cmd_num=0
target_groups=$2

# Change the ownership to prevent the error
sudo chown -R ubuntu:ubuntu $NIFI_HOME

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
while [ $cmd_num -lt $target_groups ]; do
    aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
    --document-name "AWS-RunShellScript" \
    --comment "start MiNiFi" \
    --parameters commands="sudo sh $DEFAULT_HOME/scripts/start_minifi.sh" \
    --max-concurrency 100% \
    --output text
    cmd_num=$(($cmd_num+1))
done

rm cpu.csv
cpustat -n 1 >> cpu.csv &
CPUSTAT_PID=$!

echo "$SHELL: Sleeping $1..."
# Sleep as input time.
sleep $1

# Stop MiNiFi
cmd_num=0

## Uncomment this to stop instances all at once
#aws ssm send-command --targets "Key=tag:type,Values=edge" \
#--document-name "AWS-RunShellScript" \
#--comment "stop MiNiFi" \
#--parameters commands="sudo sh /home/ubuntu/scripts/stop_minifi.sh" \
#--output text
#
while [ $cmd_num -lt $target_groups ]; do
    aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
    --document-name "AWS-RunShellScript" \
    --comment "stop MiNiFi" \
    --parameters commands="sudo $MINIFI_BIN/minifi.sh stop" \
    --max-concurrency 100% \
    --output text
    cmd_num=$(($cmd_num+1))
pkill $CPUSTAT_PID
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
echo; read -p "$SHELL: Do you want to stop NiFi server? [y/n]"
if [[ $REPLY =~ ^[Yy]$ ]]
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
echo "$SHELL: Parsing the log..."
cat $NIFI_LOG/nifi-app* >> $NIFI_LOG/log_cat

# Calculate second
if [[ $1 == *"m"* ]]; then
	num=`echo "${1//m}"`
	runtime_second=$(($num*60))
elif [[ $1 == *"s"* ]]; then
	num=`echo "${1//s}"`
	runtime_second=$num
fi

python3.5 get_thruput_cloud_merging_v1.py $NIFI_LOG/log_cat $runtime_second > $NIFI_LOG/temp

echo; echo "RESULT"; echo "------------------------------------------"
tail -n 16 $NIFI_LOG/temp; echo "------------------------------------------"; echo

# Ask if you want to save it.
echo;read -p "$SHELL: Do you want to save this log? [y/n]"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
