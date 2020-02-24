#!/bin/sh

## USAGE
## ./stop_autoscale.sh (target group)
#### e.g. (target group): 60s, 10m, 1h

SHELL=$0

if [ $# != 1 ]; then
    echo "$SHELL: USAGE: $SHELL (target group)"
    echo "$SHELL: e.g. (target group): 1, 2, 3, ..."
    exit 1
fi

#Variables
target_group=$1
instance_limit=0

group_num=0

# Start each group that has 50 instances
while [ $group_num -lt $target_group ]; do
    aws autoscaling set-desired-capacity --auto-scaling-group-name Edges_Group$group_num --desired-capacity $instance_limit --honor-cooldown
    echo "$0: Stopped group$group_num"
    group_num=$(($group_num+1))
done

