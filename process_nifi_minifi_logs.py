#!/usr/bin/python
import sys
import re
import datetime
import os

num_args=len(sys.argv)-1
if num_args != 3:
	print("Not enough arguments: <Nifi log file path> <number of edges> <minifi logs folder location>")
	sys.exit(-1)

nifi_log_name=sys.argv[1]
num_edges=sys.argv[2]
minifi_folder=sys.argv[3]

start_time_read=False
start_time_obj=datetime.datetime(1, 1, 1, 0, 0)
end_time_obj=datetime.datetime(1, 1, 1, 0, 0)
with open(nifi_log_name, 'r') as fp:
	line=fp.readline()
	while line:
		if(not start_time_read):
			if("INFO" in line):
				start_time_str=line.split(" INFO ")
				start_time_obj=datetime.datetime.strptime(start_time_str[0],'%Y-%m-%d %H:%M:%S,%f')
				start_time_read=True
			elif not "INFO" in line:
				print("Starting timestamp not found, exiting")
				sys.exit(-1)
		if("Received SHUTDOWN" in line):
			end_time_str=line.split(" INFO ")
			end_time_obj=datetime.datetime.strptime(end_time_str[0],'%Y-%m-%d %H:%M:%S,%f')
		line=fp.readline()


start_time_obj += datetime.timedelta(0,30)
end_time_obj -= datetime.timedelta(0,30)
num_finished_flow_files_nifi=0
with open(nifi_log_name,'r') as fp:
	line=fp.readline()
	while line:
		m=re.search("^(.*) INFO [.*[FinalControlProxy.putWaterMark](.*)records = (.+)$",line)
		if m:
			# Get timestamp and number of records
			curr_time=datetime.datetime.strptime(m.group(1),'%Y-%m-%d %H:%M:%S,%f')
			num_records=float(m.group(3))
			if (num_records>0) and (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
				num_finished_flow_files_nifi+=1
		line=fp.readline()
			 
total_finished_flow_files_pipeline=num_finished_flow_files_nifi*int(num_edges)
print("Actual number of finished flowfiles by pipeline: ", total_finished_flow_files_pipeline)


print("Now processing minifi files for expected count")
num_expected_flowfiles_minifi=0
if len(os.listdir(minifi_folder)) == 0:
	print("Minifi log files haven't been imported to NiFi node yet")
	sys.exit(-1)

for minifi_log in os.listdir(minifi_folder):
	with open(os.path.join(minifi_folder, minifi_log), 'r') as fp:
		line=fp.readline()
		while line:
			m=re.search("(.*) INFO \[.*New epoch entering",line)
			if m:
				curr_time=datetime.datetime.strptime(m.group(1),'%Y-%m-%d %H:%M:%S,%f')
				if (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
					num_expected_flowfiles_minifi+=1		
			line=fp.readline()

print("Expected number of flowfiles in pipeline: ", num_expected_flowfiles_minifi)
print("Start time for log analysis: ", start_time_obj)
print("End time for log analysis: ", end_time_obj)
analysis_dur_sec=(end_time_obj-start_time_obj).total_seconds()
print("log analysis duration in seconds: ", analysis_dur_sec)
actual_thruput=total_finished_flow_files_pipeline/analysis_dur_sec
expected_thruput=num_expected_flowfiles_minifi/analysis_dur_sec
print("Actual throughput: ", actual_thruput)
print("Expected throughput: ", expected_thruput)
