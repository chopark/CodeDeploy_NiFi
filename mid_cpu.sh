#!/bin/bash
cp cpu.csv "$1.csv"
cat cpu.csv | grep java | awk '{print $1}' > $1
python3.5 get_mid_cpu.py $1
