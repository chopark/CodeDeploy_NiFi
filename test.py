#!/usr/bin/python
import sys
import re
import datetime
import os

minifi_folder=sys.argv[1]

start_time_obj=datetime.datetime(2021, 3, 5, 2, 8, 39)
end_time_obj=datetime.datetime(2021, 3, 5, 2, 8, 42)

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

