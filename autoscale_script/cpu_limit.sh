#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (sleep time) (target groups)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (target groups): 1, 2, 3, ..."

SHELL=$0

if [ $# != 2 ]; then
    echo "$SHELL: USAGE: $SHELL (cpulimit) (target groups)"
    echo "$SHELL: e.g. (cpulimit): 10, 20, ..."
    echo "$SHELL: e.g. (target groups): 1, 2, 3, ..."
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
    aws ssm send-command --targets "Key=tag:command,Values=$cmd_num" \
    --document-name "AWS-RunShellScript" \
    --comment "start MiNiFi" \
    --parameters commands="sudo sh $HOME/scripts/limit_cpu.sh $1" \
    --max-concurrency 100% \
    --output text
    cmd_num=$(($cmd_num+1))
done

echo "Done!"


