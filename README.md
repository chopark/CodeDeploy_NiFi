**Table of Contents**
- [Scripts](#scripts)
- [For new instance](#for-new-instance)
  - [install_deps.sh](#install_depssh)
- [Changing id of edges](#changing-id-of-edges)
  - [set_edgeId.sh](#set_edgeidsh)
- [Changing resources of edges](#changing-resources-of-edges)
  - [network_limit.sh](#network_limitsh)
- [Start experiment](#start-experiment)
  - [run_exp.sh](#run_expsh)
- [Process results](#process-results)
  - [get_mid_cpu.sh](#get_mid_cpush)
  - [get_log.sh](#get_logsh)

# Scripts
* All scripts in `~/CodeDeploy_NiFi/`
* [GitHub](https://github.com/chopark/CodeDeploy_NiFi)

# For new instance
## install_deps.sh
* Install dependencies when you launch new nifi instance

# Changing id of edges
## set_edgeId.sh
* setup edges id
* 
```console
$ bash set_edgeId.sh

// Also works without sh
$ ./set_edgeId.sh
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
* Possible to change the time parameter time_limit=date "+%H%M" -d "**+# min**" in line 73,76,80.
* The minimum time unit is minute due to using Linux 'at' command
* Automatically kill cpulimit program before 1 minute of new cpulimit execution

```console
$ sh run_exp.sh (sleep time) (the number of target edge group) (CPU resource after 1 minute) (CPU resource after 3 minutes) (CPU resource after 5 minutes)
// Start the experiment with edge group named '1' for 1 minutes
$ bash run_exp.sh 1m 1

// Start the experiment with cpulimit
// After 1 minute: 30% limit, After 2 minutes: No limit, After 3 minutes: 50% limit, After 4 minutes: No limit, After 5 minutes: 80% limit
$ bash run_exp.sh 6m 1 30 50 80

// Also works without sh
$ ./run_exp.sh 1m 1
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