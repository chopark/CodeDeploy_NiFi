#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (sleep time) (target groups)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (target groups): 1, 2, 3, ..."

SHELL=`basename "$0"`

if [ $# != 2 ]; then
    echo "$SHELL: USAGE: $SHELL (upload bandwidth(Kbps)) (the number of target edge group)"
    echo "$SHELL: e.g. (upload bandwidth(Kbps): 10000, 20000, ..."
    echo "$SHELL: e.g. (the number of target edge group):  1, 2, 3, ..."
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


# change this to use in other instances...
cmd_num=0
target_groups=$2


while [ $cmd_num -lt $target_groups ]; do
    #aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
    aws ssm send-command --targets "Key=tag:deploy,Values=$cmd_num" \
    --document-name "AWS-RunShellScript" \
    --comment "Set network group$cmd_num" \
    --parameters commands="sudo sh $HOME/scripts/limit_netband.sh $1" \
    --max-concurrency 100% \
    --output text
    cmd_num=$(($cmd_num+1))
done

echo "Done!"


