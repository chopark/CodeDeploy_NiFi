#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (sleep time) (target groups)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (target groups): 1, 2, 3, ..."

SHELL=`basename "$0"`

if [ $# != 1 ]; then
    echo "$SHELL: USAGE: $SHELL"
    exit 1
fi

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

IP=`hostname -i`
group_num=0
target_groups=$1

while [ $group_num -lt $target_groups ]; do
    aws ssm send-command --targets "Key=tag:command,Values=$group_num" \
    --document-name "AWS-RunShellScript" \
    --comment "set config MiNiFi Group$group_num" \
    --parameters commands="sudo sh $HOME/scripts/change_port.sh $group_num $IP" \
    --max-concurrency 100% \
    --output text
    group_num=$(($group_num+1))
done
echo "Set config files"
