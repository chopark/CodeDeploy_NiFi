#!/usr/bin/py
import sys
import statistics

file_name=sys.argv[1]
edge_query_latencies=[]
cloud_query_latencies=[]
network_latencies=[]
overall_latencies=[]
flowfile_sizes=[]
edge_query_file_sizes=[]
cloud_query_file_sizes=[]
final_file_sizes=[]

edge_ips={}

with open(file_name,'r') as fp:
	line=fp.readline()
	while line:
		if "m_final_now" in line and "Key" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			final_now=float(split_line[1])
		if "m_network_now" in line and "Key" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			network_now=float(split_line[1])
			cloud_query_latencies.append(final_now-network_now)
		if "m_query_now" in line and "Key" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			query_now=float(split_line[1])
			try:
				network_now
			except NameError:				
				# Do nothing
				pass
			else:
				network_latencies.append(network_now-query_now)
		if "m_source_now" in line and "Key" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			source_now=float(split_line[1])
			edge_query_latencies.append(query_now-source_now)		
			overall_latencies.append(final_now-source_now)
		if "origFileSize" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			flowfile_sizes.append(float(split_line[1]))
		if "m_query_filesize" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			edge_query_file_sizes.append(float(split_line[1]))
		if "m_final_filesize" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			final_file_sizes.append(float(split_line[1]))
		if "s2s.host" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			if not "ec2.internal" in split_line[1]:
				split_line[1] = "ip-"+line.replace(".","-").rstrip("\n").lstrip("\tValue: ")+".ec2.internal"
			if not split_line[1] in edge_ips:
				edge_ips[split_line[1]]=1
			else:
				edge_ips[split_line[1]]+=1
		line=fp.readline()

# Display latencies
print("Raw network latency values:")
for net_lat in network_latencies:
	print(net_lat)

print("Raw edge_query latency values:")
for query_lat in edge_query_latencies:
	print(query_lat)

print("Raw cloud_query latency values:")
for query_lat in cloud_query_latencies:
	print(query_lat)

print("Raw overall latency values:")
for overall_lat in overall_latencies:
	print(overall_lat)

# Calculate latency summaries
if len(network_latencies) > 0:
	print("Network latency:",str(statistics.mean(network_latencies)),"+-",str(statistics.stdev(network_latencies)))
	print("Cloud query latency:",str(statistics.mean(cloud_query_latencies)),"+-",str(statistics.stdev(cloud_query_latencies)))

print("Edge query latency:",str(statistics.mean(edge_query_latencies)),"+-",str(statistics.stdev(edge_query_latencies)))
print("Overall latency:",str(statistics.mean(overall_latencies)),"+-",str(statistics.stdev(overall_latencies)))

# Flow file sizes
print("Orig Flowfile sizes:",str(statistics.mean(flowfile_sizes)),"+-",str(statistics.stdev(flowfile_sizes)))
print("Query Flowfile sizes:",str(statistics.mean(edge_query_file_sizes)),"+-",str(statistics.stdev(edge_query_file_sizes)))
print("Final Flowfile sizes:",str(statistics.mean(final_file_sizes)),"+-",str(statistics.stdev(final_file_sizes)))

# Calculate bandwidth
flowfile_begin=0
flowfile_start=0
flowfile_end=0
flowfile_count=0
source_data_gen=0
source_first_now=-1
source_last_now=0
edge_query_first_now=-1
edge_query_last_now=0
cloud_query_first_now=-1
cloud_query_last_now=0
with open(file_name,'r') as fp:
	line=fp.readline()
	while line:
		if "m_source_flowfile_start" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			flowfile_start=int(split_line[1])
			if flowfile_count==0:
				flowfile_begin=flowfile_start
			flowfile_count+=1
		if "m_final_now" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			flowfile_end=int(split_line[1])
		if "origFileSize" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			source_data_gen+=float(split_line[1])
		if "m_source_now" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			if source_first_now==-1:
				source_first_now=int(split_line[1])
			source_last_now=int(split_line[1])
		if "m_query_now" in line:
                        line=fp.readline()
                        line=line.replace("'","")
                        split_line=line.split()
                        if edge_query_first_now==-1:
                                edge_query_first_now=int(split_line[1])
                        edge_query_last_now=int(split_line[1])
		if "m_network_now" in line:
                        line=fp.readline()
                        line=line.replace("'","")
                        split_line=line.split()
                        if cloud_query_first_now==-1:
                                cloud_query_first_now=int(split_line[1])
                        cloud_query_last_now=int(split_line[1])
		line=fp.readline()

duration=float((flowfile_end-flowfile_begin))/1000 #divide to convert to seconds
total_data=float(flowfile_count*statistics.mean(flowfile_sizes))/(1024*1024) #divide to convert to MB
bandwidth=total_data/duration
source_data_total=source_data_gen/(1024*1024)
source_throughput=source_data_total/((source_last_now-source_first_now)/1000)

# QueryRecord throughput
edge_query_throughput=source_data_total/((edge_query_last_now-edge_query_first_now)/1000)
if len(network_latencies) > 0:
	cloud_query_throughput=source_data_total/((cloud_query_last_now-cloud_query_first_now)/1000)

print("Total run duration: ",str(duration))
print("Total data processed: ",str(total_data))
print("Actual Thruput: ",str(bandwidth)," MBps")
print("Expected source throughput: ",str(source_throughput)," MBps")
print("Edge Query Thruput: ",str(edge_query_throughput)," MBps")

if len(network_latencies) > 0:
	print("Cloud Query Thruput: ",str(cloud_query_throughput)," MBps")
print("Edge IPs and their associated flowfile counts on cloud side:")
print(edge_ips)
print("Edge IPs len: ",str(len(edge_ips)))
