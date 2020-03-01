#!/bin/sh

## USAGE
## ./start_autoscale.sh (target group)
#### e.g. (target group): 60s, 10m, 1h

SHELL=$0

if [ $# != 1 ]; then
    echo "$SHELL: USAGE: $SHELL (target group)"
    echo "$SHELL: e.g. (target group): 1, 2, 3, ..."
    exit 1
fi

#Variables
target_group=$1
instance_limit=150

group_num=0
count=0
# Start each group that has 50 instances
while [ $group_num -lt $target_group ]; do
    if [ $count -gt 14 ]; then
        echo "$0: Sleep 30s to prevent requestexceed issue"
        sleep 60s
        count=0
    fi
    aws autoscaling set-desired-capacity --auto-scaling-group-name Edges_Group$group_num --desired-capacity $instance_limit --honor-cooldown
    echo "$0: Started group$group_num"
    count=$(($count+1))
    group_num=$(($group_num+1))
done

