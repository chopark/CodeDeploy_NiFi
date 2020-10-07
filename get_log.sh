#!/bin/bash
## USAGE
## ./wait_and_process_results.sh (sleep time) (target groups)
#### e.g. (sleep time): 60s, 10m, 1h
#### e.g. (target groups): 1, 2, 3, ..."

SHELL=`basename "$0"`

if [ $# != 0 ]; then
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
declare -a instanceId

# str=$(aws ec2 describe-instances --filters "Name=tag:type,Values=edge" --query 'Reservations[].Instances[].[PrivateIpAddress,InstanceId,Tags[?Key==`Name`].Value[]]' --output text | sed 's/None$/None\n/' | sed '$!N;s/\n/ /' | awk '{print $2;}')
str=$(aws ec2 describe-instances --filters "Name=instance-state-code,Values=16" "Name=tag:type,Values=edge" --query 'Reservations[].Instances[].[PrivateIpAddress,InstanceId,Tags[?Key==`Name`].Value[]]' --output text | sed 's/None$/None\n/' | sed '$!N;s/\n/ /' | awk '{print $1;}')
instanceId=(
	${str}
)

for (( i=0; i<${#instanceId[@]}; i++ )); do
	scp -o StrictHostKeyChecking=no -i "jarvis.pem" ubuntu@${instanceId[i]}:~/minifi/minifi-0.5.0/logs/minifi-app.log ~/logs/minifi-app$i.log
done

