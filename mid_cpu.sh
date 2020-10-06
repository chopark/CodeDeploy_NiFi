#!/bin/bash
cat cpu.csv | grep java | awk '{print $1}' > $1
python3.7 get_mid_cpu.py $1