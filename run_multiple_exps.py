#!/usr/bin/python

import subprocess
num_groups=1
while num_groups<5:
	#subprocess.call("sudo bash /home/ubuntu/CodeDeploy_NiFi/run_exp.sh 6m $num_groups 4 75")
	filename="temp{}".format(num_groups)
	f=open(filename, "w")
	arg="{}".format(num_groups)
	subprocess.call(["sudo", "bash", "/home/ubuntu/CodeDeploy_NiFi/network_limit.sh", "20000", "11"])
	subprocess.call(["sudo", "bash", "/home/ubuntu/CodeDeploy_NiFi/run_exp.sh", "false", "6m", arg, "4", "75"], stdout=f)
	#subprocess.call(["sudo", "bash", "/home/ubuntu/CodeDeploy_NiFi/print_date.sh", arg], stdout=f)
	#subprocess.call(["sudo", "date"], stdout=f)
	num_groups+=1
