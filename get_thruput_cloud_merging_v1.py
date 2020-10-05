#!/usr/bin/py
import sys
import statistics

file_name=sys.argv[1]

# Size is in MB
epochDataSize=3.4

numFlowFiles=0
totalEpochsToProcess=0
edge_ips={}

with open(file_name,'r') as fp:
	line=fp.readline()
	while line:
		"""
		if "fileSize" in line and "Key" in line:
			line=fp.readline()
			line=line.replace("'","")
			split_line=line.split()
			flowfileSize=int(split_line[1])
			if flowfileSize==318556:
				numFlowFiles+=1
		"""
		if "Edge ID and epoch ID" in line:
			split_line=line.split()
			#totalEpochsToProcess=int(split_line[len(split_line)-1])
			ids=split_line[len(split_line)-1].split(',')
			if not ids[0] in edge_ips:
				edge_ips[ids[0]]=int(ids[1])
			else:
				edge_ips[ids[0]]=max(int(ids[1]), edge_ips[ids[0]])
		line=fp.readline()

print("Edge IDs along with the final epoch ID seen from each edge:")
print(edge_ips)
print("The number of edges:", len(edge_ips))
totalSize=0
for key in edge_ips:
	totalSize+=((edge_ips[key]+1) * epochDataSize)

print("Total data size processed across all edges is: ", totalSize, " MB")
