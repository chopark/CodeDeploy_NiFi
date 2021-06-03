**Table of Contents**
- [Additional README](#additional-readme)
- [Scripts](#scripts)
- [For new instance](#for-new-instance)
  - [install_deps.sh](#install_depssh)
- [Changing id of edges](#changing-id-of-edges)
  - [set_edgeId.sh](#set_edgeidsh)
- [Changing ports](#changing-ports)
  - [set_conf.sh](#set_confsh)
- [Changing resources of edges](#changing-resources-of-edges)
  - [network_limit.sh](#network_limitsh)
- [Start experiment](#start-experiment)
  - [run_exp.sh](#run_expsh)
- [Process results](#process-results)
  - [get_mid_cpu.sh](#get_mid_cpush)
  - [get_log.sh](#get_logsh)

# Additional README
* [Link](./README)

# Scripts
* All scripts in `~/CodeDeploy_NiFi/`

# For new instance
## install_deps.sh
* Install dependencies when you launch new nifi instance

# Changing id of edges
## set_edgeId.sh
* setup edges id
 
```console
$ bash set_edgeId.sh

// Also works without sh
$ ./set_edgeId.sh
```

# Changing ports
## set_conf.sh
* Change ports with total groups

```console
$ bash set_conf.sh (total groups)

// Set From MiNiFi port to group number 0, Set From MiNiFi1 port to group number 1, ..., and so on.
$ bash set_conf.sh 2

// Also works without sh
$ ./set_conf.sh 2
```

# Changing resources of edges
## network_limit.sh
* Change the network upload bandwidth of edges

```console
$ bash network_limit.sh (upload bandwidth(Kbps)) (the number of target edge group)

// Set upload bandwidth of 10 edges as 10 Mbps
$ bash network_limit.sh 10240 1

// Also works without sh
$ ./network_limit.sh 10240 1
```

I set the current target edge group "1" as 10 edges.

# Start experiment
## run_exp.sh 
* Run experiment with edges
* limit CPU resources of each edge with arguments
* (Interactive): Directive process with script
  * e.g. true, false
* (Sleep time): Experiment runtime
  * e.g.  60s, 10m, 1h, ...
* (Target groups): The number of AWS Autoscale groups
  * e.g. 1, 2, 3, ...
* (number of nodes per group): The number of instances in each AWS Autoscale group
  * e.g. 4, 8, ...
* (number of wms to skip during log analysis): Skip the number of instances
  * e.g. 4, 8, ...

```console
$ sh run_exp.sh (interactive) (sleep time) (target groups) (number of nodes per group) (number of wms to skip for analysis)
// Start the experiment with edge group named '1' for 1 minutes
$ bash run_exp.sh true 1m 1 4 0

// Also works without sh
$ ./run_exp.sh true 1m 1 4 0
```

# Process results
`run_exp.sh` executes the `get_thruput_cloud_merging_v1.py` and `get_mid_cpu.sh`, but it sometimes fails. The followings are manual scripts.

## get_mid_cpu.sh
* Automatically launch in `run_exp.sh` when parsing the logs
* get median CPU utilization from cpustat
```console
$ ./get_mid_cpu.sh
```

## get_log.sh
* Get logs from currently running minifi on `~/temp-jarvis/minifi_logs/`
* **Need to change `jarvis.pem` and name of .pem files in this script** if you try with new account.