#!/bin/bash
LOG_DIR=~/logs

if [ ! -d $LOG_DIR ]; then
    mkdir $LOG_DIR
fi

cp cpu.csv "$LOG_DIR/$1.csv"
cat cpu.csv | grep java | awk '{print $1}' > temp
python3 mid_cpu.py temp
rm -rf temp
