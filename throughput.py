import sys

def calcu(flow_num, time, edge_num):
   return flow_num * 27.2 / time / edge_num

if __name__ == "__main__":
    print("Throughput: ",calcu(float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])),"Mbps")
