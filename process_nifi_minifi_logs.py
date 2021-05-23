#!/usr/bin/python
import sys
import re
import datetime
import os
from statistics import median

def parse_timestamp(re_match):
	# Get timestamp
	curr_time=datetime.datetime.strptime(re_match,'%Y-%m-%d %H:%M:%S,%f')
	return curr_time
	

num_args=len(sys.argv)-1
if num_args != 4:
	print("Not enough arguments: <Nifi log file path> <number of edges> <minifi logs folder location> <Number of watermarks to skip>")
	sys.exit(-1)


nifi_log_name=sys.argv[1]
num_edges=sys.argv[2]
minifi_folder=sys.argv[3]
num_wm_skip=int(sys.argv[4])

start_time_read=False
start_time_obj=datetime.datetime(1, 1, 1, 0, 0)
end_time_obj=datetime.datetime(1, 1, 1, 0, 0)
num_watermarks_seen=0
with open(nifi_log_name, 'r') as fp:
	line=fp.readline()
	while line:
		if(not start_time_read):
			m=re.search("^(.*) INFO [.*[FinalControlProxy.putWaterMark](.*)records = (.+), with per item size: (.+)$",line)
			if m:
				curr_time=parse_timestamp(m.group(1))
				num_records=float(m.group(3))
				#if(num_records>0):
				num_watermarks_seen+=1
				if num_watermarks_seen == num_wm_skip:
					start_time_obj=curr_time		
					start_time_read=True
		"""	
			if("INFO" in line):
				start_time_str=line.split(" INFO ")
				start_time_obj=datetime.datetime.strptime(start_time_str[0],'%Y-%m-%d %H:%M:%S,%f')
				start_time_read=True
			elif not "INFO" in line:
				print("Starting timestamp not found, exiting")
				sys.exit(-1)
		"""
		#if("Received SHUTDOWN" in line):
		#	end_time_str=line.split(" INFO ")
		#	end_time_obj=datetime.datetime.strptime(end_time_str[0],'%Y-%m-%d %H:%M:%S,%f')
		if("ERROR" in line and ("Ghost" not in line and ("Site-to-Site Worker" not in line or "EOFException" not in line) and ("Site-to-Site Worker" not in line or "java.net.SocketTimeoutException" not in line) and ("Site-to-Site Worker" not in line or "RequestExpiredException" not in line) and ("SocketRemoteSiteListener Unable to communicate with remote instance" not in line))):
			print("Some error occurred during the experiment run. Investigate")
			print(line)
			sys.exit(-1)			
		line=fp.readline()


#start_time_obj += datetime.timedelta(0,30)
#end_time_obj -= datetime.timedelta(0,30)
end_time_obj=start_time_obj+datetime.timedelta(0,120)
num_finished_flow_files_nifi=0
nifi_wm_processed_ts={}
nifi_wm_arrival_ts={}
with open(nifi_log_name,'r') as fp:
	line=fp.readline()
	while line:
		m=re.search("^(.*) INFO [.*[FinalControlProxy.putWaterMark](.*)records = (.+), with per item size: (.+)$",line)
		if m:
			curr_time=parse_timestamp(m.group(1))
			num_records=float(m.group(3))
			#if (num_records>0) and (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
			if (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
				num_finished_flow_files_nifi+=1
		# Track all watermarks after processing on nifi side
		m=re.search("^(.*) INFO [.*[CustomDnnHashGlobalAggOperator.onComplete](.*)sent watermark (.+)$",line)
		if m:
			curr_time=parse_timestamp(m.group(1))
			nifi_wm_processed_ts[int(m.group(3))]=curr_time
		
		# Track all watermarks after processing on nifi side
		m=re.search("^(.*) INFO [.*[CustomHashGlobalAggOperator.onComplete](.*)sent watermark (.+)$",line)
		if m:
			curr_time=parse_timestamp(m.group(1))
			nifi_wm_processed_ts[int(m.group(3))]=curr_time

		# Track all watermarks when they enter on nifi SP side 
		m=re.search("^(.*) INFO \[(.*)MyProcessor.extractRecords] Final watermark seen is: (.+)$",line)
		if m:
			curr_time=parse_timestamp(m.group(1))
			nifi_wm_arrival_ts[int(m.group(3))]=curr_time

		line=fp.readline()
			 
total_finished_flow_files_pipeline=num_finished_flow_files_nifi*int(num_edges)
print("Actual number of finished flowfiles by pipeline: ", total_finished_flow_files_pipeline)
print("Start time for log analysis: ", start_time_obj)
print("End time for log analysis: ", end_time_obj)
print("Now processing minifi files for expected count")
num_expected_flowfiles_minifi=0
if len(os.listdir(minifi_folder)) == 0:
	print("Minifi log files haven't been imported to NiFi node yet")
	sys.exit(-1)

total_minifi_flowfiles_gen=0

minifi_wm_startts_list=[] # Computing latencies
minifi_wm_left_ds_list=[]
for minifi_log in os.listdir(minifi_folder):
	with open(os.path.join(minifi_folder, minifi_log), 'r') as fp:
		print("Minifi log file name being read is: ", minifi_log)
		line=fp.readline()
		minifi_wm_start_ts={}
		minifi_wm_left_ds_ts={}
		linenum=0
		while line:
			linenum+=1
			m=re.search("(.*) INFO \[.*New epoch entering.*num will be: (\d+)",line)
			if m:
				total_minifi_flowfiles_gen+=1
				curr_time=parse_timestamp(m.group(1))
				if (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
					num_expected_flowfiles_minifi+=1
					minifi_wm_start_ts[int(m.group(2))]=curr_time

			# Tracking wm timestamp when it leaves data source
			m=re.search("(.*) INFO \[.*FinalControlProxy.putWaterMark] Seen watermark in final queue with seq num: (\d+),",line)
			if m:
				curr_time=parse_timestamp(m.group(1))
				if (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
					minifi_wm_left_ds_ts[int(m.group(2))]=curr_time
			
			# Tracking wm timestamp when it leaves data source for no adapt control proxy
			m=re.search("(.*) INFO \[.*FinalControlProxyNoAdapt.putWaterMark] Seen watermark in final queue with seq num: (\d+),",line)
			if m:
				curr_time=parse_timestamp(m.group(1))
				if (curr_time <= end_time_obj) and (curr_time >= start_time_obj):
					minifi_wm_left_ds_ts[int(m.group(2))]=curr_time
			try:
				line=fp.readline()
			except:
				print("line num after which failure occurred:", linenum)
				raise Exception("problem reading log file")
		minifi_wm_startts_list.append(minifi_wm_start_ts)
		minifi_wm_left_ds_list.append(minifi_wm_left_ds_ts)

print("Expected number of flowfiles in pipeline: ", num_expected_flowfiles_minifi)
analysis_dur_sec=(end_time_obj-start_time_obj).total_seconds()
print("log analysis duration in seconds: ", analysis_dur_sec)
actual_thruput=total_finished_flow_files_pipeline/analysis_dur_sec
expected_thruput=num_expected_flowfiles_minifi/analysis_dur_sec
print("Actual throughput in terms of flowfiles: ", actual_thruput)
print("Expected throughput in terms of flowfiles: ", expected_thruput)
print("Total number of minifi flowfiles generated: ", total_minifi_flowfiles_gen)

print("Printing wms")
# Compute average data source processing latency
minifi_proc_latency=[]
for i in range(len(minifi_wm_startts_list)):
	for wm,ts in minifi_wm_startts_list[i].items():
		if wm in minifi_wm_left_ds_list[i]:
			delay=minifi_wm_left_ds_list[i][wm] - ts
			minifi_proc_latency.append(delay.total_seconds())
print("Stats for minifi proc latency:", max(minifi_proc_latency), median(minifi_proc_latency), min(minifi_proc_latency))

# Compute average network latency
print("Printing nifi wm arrival ts")
network_delays=[]
for i in range(len(minifi_wm_startts_list)):
	for wm,ts in minifi_wm_startts_list[i].items():
		if wm in nifi_wm_arrival_ts and wm in minifi_wm_left_ds_list[i]:
			net_delay=nifi_wm_arrival_ts[wm]-minifi_wm_left_ds_list[i][wm]
			network_delays.append(net_delay.total_seconds())
print("Stats for network latency:", max(network_delays), median(network_delays), min(network_delays))

print("Computing latencies")
max_wm_ts={}
num_wm_occurrences={}

# Calculating number of expected wm occurrences
expected_wm_occurrences=0
for minifi_wms in minifi_wm_startts_list:
	if len(minifi_wms) > 0:
		expected_wm_occurrences+=1
#expected_wm_occurrences=len(minifi_wm_startts_list)
for minifi_wms in minifi_wm_startts_list:
	for wm,ts in minifi_wms.items():
		if wm in max_wm_ts:
			num_wm_occurrences[wm]+=1
			if ts > max_wm_ts[wm]:
				max_wm_ts[wm]=ts
		else:
			num_wm_occurrences[wm]=1
			max_wm_ts[wm]=ts

"""
print(max_wm_ts)
print("Nifi wm")
print(nifi_wm_processed_ts)
"""
lat_seconds=[]

# Compute average SP processing latency
nifi_proc_latency=[]
for wm,max_ts in max_wm_ts.items():
	if num_wm_occurrences[wm]==expected_wm_occurrences:
		if not wm in nifi_wm_processed_ts:
			print(wm, " is not in nifi_wm_processed_ts")
			continue
		if not wm in nifi_wm_arrival_ts:
			print(wm, " is not in nifi_wm_arrival_ts")
			continue
		proc_latency=nifi_wm_processed_ts[wm]-nifi_wm_arrival_ts[wm]
		latency=nifi_wm_processed_ts[wm]-max_ts
		lat_seconds.append(latency.total_seconds())
		nifi_proc_latency.append(proc_latency.total_seconds())
		print("latency: ", latency.total_seconds(), " and nifi proc latency is: ", proc_latency.total_seconds(), ", for wm: ", wm)	
print("Average latency per flowfile is:", max(lat_seconds), median(lat_seconds), min(lat_seconds)) 
