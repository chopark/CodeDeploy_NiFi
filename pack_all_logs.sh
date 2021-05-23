#!/bin/bash
## USAGE
## ./run_exp.sh (sleep time) (the number of target edge group)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (the number of target edge group): 1, 2, 3, ..."

SHELL=`basename "$0"`
EXPECTED_ARGS=3

if [ $# -ne $EXPECTED_ARGS ]; then
    echo "$SHELL: Arguments needed <number of DS nodes> <halfsrc/jarvis> <replication factor on nifi>"
    exit 1
fi

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


sudo cp $NIFI_LOG/log_cat $MINIFI_LOGS_LOCATION/
tar_file="all_logs_$1nodes_$2_netlimit_replica$3.tar.gz"
sudo tar -czvf "$tar_file" $MINIFI_LOGS_LOCATION
sudo mv $tar_file $MINIFI_LOGS_LOCATION/..

read -p "Done transferring file to local machine(y/n)?" transferred
if [ "$transferred" == "y" ]; then
	sudo rm $MINIFI_LOGS_LOCATION/../$tar_file	
fi	
