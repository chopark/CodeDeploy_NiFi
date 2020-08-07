import sys

flow=float(sys.argv[1])
time=float(sys.argv[2])
edges=float(sys.argv[3])

size=8*flow*3.4/time/edges
print("Throughput: ",size,"Mbps")
