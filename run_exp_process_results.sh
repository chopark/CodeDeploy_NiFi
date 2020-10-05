#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (sleep time)
#### e.g. (sleep time): 60s, 10m, 1h

SHELL=$0

if [ $# != 1 ]; then
    echo "$SHELL: USAGE: $SHELL (sleep time)"
    echo "$SHELL: e.g. (sleep time): 60s, 10m, 1h"
    exit 1
fi

# Directories
HOME="/home/ubuntu"
NIFI_HOME="$HOME/jarvis-nifi"
NIFI_LOG="$NIFI_HOME/logs"
NIFI_SCRIPT="$NIFI_HOME/scripts"
NIFI_BIN="$NIFI_HOME/bin"
NIFI_RESULTS="$NIFI_HOME/results"
MINIFI_DIR="$HOME/jarvis-minifi/minifi"
MINIFI_HOME="$MINIFI_DIR/minifi-0.5.0"
MINIFI_BIN="$MINIFI_HOME/bin"
MINIFI_SCRIPT="$MINIFI_DIR/scripts"

# Start NiFi
sudo sh $NIFI_SCRIPT/restart_nifi.sh

# Get your current server ip.
IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
FINAL_QUEUE_ID="ec73aa70-0174-1000-f201-66b549d134a8"
#FINAL_QUEUE_ID="e698454e-0174-1000-395e-0ac12663fd63"
LOG_PROCESSOR_ID="d02bb153-016c-1000-3bed-7ffc10e019d1"
#LOG_PROCESSOR_ID="e698247f-0174-1000-1c40-f3a6ff2da6c0"

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
echo "NiFi ready, start MiNiFi and click 2 characters to proceed"; echo

# For getting CPU utilization, run the following: "cpustat -x -D -a -n 1 1 10"

read -n 2

echo "$SHELL: FlowFiles will be parsed with your NiFi IP($IP)"; echo;
echo "$SHELL: Sleeping $1..."; echo;
# Sleep as input time.
sleep $1

echo "$SHELL: Stop MiNiFi now";echo;
read -n 2

echo "$SHELL: Checking flowFilesQueued...";echo;
# Parse flowFilesQueued.
FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"; echo;

# If the final queue in our dataflow contains any pending flowfiles to be processed, clean it.
# After text '--data-binary', calling $LOG_PROCESSOR_ID did not work for some reason. So I put the ID value instead of $LOG_PROCESSOR_ID.
if [ ! -z "$FLOWFILESQUEUED" -a "$FLOWFILESQUEUED" != 0 ]; then
    echo "$SHELL: Cleaning up pending flowfiles..."

    curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"d02bb153-016c-1000-3bed-7ffc10e019d1","version":0},"component":{"id":"d02bb153-016c-1000-3bed-7ffc10e019d1","state":"RUNNING"}}';echo; echo;
    #curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"e698247f-0174-1000-1c40-f3a6ff2da6c0","version":0},"component":{"id":"e698247f-0174-1000-1c40-f3a6ff2da6c0","state":"RUNNING"}}';echo; echo;
    
    while [ $FLOWFILESQUEUED != 0 ] ; do
        sleep 2s
        FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
        echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED";echo;
    done
    
    echo; curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"d02bb153-016c-1000-3bed-7ffc10e019d1","version":0},"component":{"id":"d02bb153-016c-1000-3bed-7ffc10e019d1","state":"STOPPED"}}';echo
    #echo; curl "http://$IP:8080/nifi-api/processors/$LOG_PROCESSOR_ID" -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"e698247f-0174-1000-1c40-f3a6ff2da6c0","version":0},"component":{"id":"e698247f-0174-1000-1c40-f3a6ff2da6c0","state":"STOPPED"}}';echo
fi  

FLOWFILESQUEUED=`curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | cut -d: -f61 | cut -d, -f1`
echo "$SHELL: flowFilesQueued: $FLOWFILESQUEUED"

# Stop NiFi
echo; read -p "$SHELL: Do you want to stop NiFi server? [y/n]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo; echo "$SHELL: Stop running Nifi instance..."
	sudo sh $NIFI_BIN/nifi.sh stop
fi

# If there is old log_cat file, delete it.
if [ -f "$NIFI_LOG/log_cat" ]; then
    echo "$SHELL: Remove previous log_cat...";echo;
    rm $NIFI_LOG/log_cat
fi

# Parse the log and show the result.
echo "$SHELL: Parsing the log..."; echo;
cat $NIFI_LOG/nifi-app* >> $NIFI_LOG/log_cat
#python3.5 $NIFI_SCRIPT/extract_latencies.py $NIFI_LOG/log_cat > $NIFI_LOG/temp
python3.5 $NIFI_SCRIPT/get_thruput_cloud_merging_v1.py $NIFI_LOG/log_cat > $NIFI_LOG/temp

echo; echo "RESULT"; echo "------------------------------------------"
tail -n 5 $NIFI_LOG/temp; echo "------------------------------------------"; echo

# Ask if you want to save it.
echo;read -p "$SHELL: Do you want to save this log? [y/n]" -n 1 -r
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
