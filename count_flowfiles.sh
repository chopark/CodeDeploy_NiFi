#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (time) (edges)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (target groups): 1, 2, 3, ..."

# Directories
HOME="/home/ubuntu"
NIFI_HOME="$HOME/jarvis-nifi"
NIFI_LOG="$NIFI_HOME/logs"
NIFI_SCRIPT="$NIFI_HOME/scripts"
NIFI_BIN="$NIFI_HOME/bin"
NIFI_RESULTS="$NIFI_HOME/results"
MINIFI_DIR="$HOME/minifi"
MINIFI_HOME="$MINIFI_DIR/minifi-0.5.0"
MINIFI_BIN="$MINIFI_HOME/bin"
MINIFI_SCRIPT="$MINIFI_DIR/scripts"

time=$1
edges=$2

flowfiles=`cat $NIFI_LOG/nifi-app.log | grep -c "o.a.n.r.p.s.SocketFlowFileServerProtocol SocketFlowFile"`
echo "Flowfiles=$flowfiles"
python3 count.py $flowfiles $time $edges
