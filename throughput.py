import sys

def calcu(flow_num, time):
   return flow_num * 0.419746399 / time

if __name__ == "__main__":
    print("Throughput: ",calcu(float(sys.argv[1]), float(sys.argv[2])),"MBps")
