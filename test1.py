#!/usr/bin/py
import sys
import re
import datetime
nifi_log_name=sys.argv[1]
def parse_timestamp(re_match):
        # Get timestamp
        curr_time=datetime.datetime.strptime(re_match,'%Y-%m-%d %H:%M:%S,%f')
        return curr_time


nifi_wm_arrival_ts={}
with open(nifi_log_name,'r') as fp:
	line=fp.readline()
	while line:
		# Track watermarks when they enter on nifi SP side 
		m=re.search("^(.*) INFO \[(.*)MyProcessor.extractRecords] Final watermark seen is: (.+)$",line)
		if m:
			print(m.group(1))
			curr_time=parse_timestamp(m.group(1))
			nifi_wm_arrival_ts[int(m.group(3))]=curr_time
		line=fp.readline()

print(nifi_wm_arrival_ts)
