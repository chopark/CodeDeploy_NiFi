#!/usr/bin/py
import sys
import statistics
import pandas as pd

filename=sys.argv[1]

df=pd.read_csv(filename, header=None, names=["cpu"])
print("CPU min: ",df["cpu"].min())
print("CPU median: ",df["cpu"].median())
print("CPU max: ",df["cpu"].max())
