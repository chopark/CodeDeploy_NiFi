#!/bin/bash

SHELL=$0

HOME="/mnt/ram_disk"
NIFI_HOME="$HOME/jarvis-nifi"
NIFI_LOG="$NIFI_HOME/logs"
NIFI_SCRIPT="$NIFI_HOME/scripts"
NIFI_BIN="$NIFI_HOME/bin"
NIFI_RESULTS="$NIFI_HOME/results"
MINIFI_DIR="$HOME/jarvis-minifi/minifi"
MINIFI_HOME="$MINIFI_DIR/minifi-0.5.0"
MINIFI_BIN="$MINIFI_HOME/bin"
MINIFI_SCRIPT="$MINIFI_DIR/scripts"

sudo chown -R ubuntu:ubuntu $NIFI_LOG

# If there is old log_cat file, delete it.
if [ -f "$NIFI_LOG/log_cat" ]; then
    echo "$SHELL: Remove previous log_cat...";echo;
    rm $NIFI_LOG/log_cat
fi

# Parse the log and show the result.
echo "$SHELL: Parsing the log..."; echo;
cat $NIFI_LOG/nifi-app* >> $NIFI_LOG/log_cat
python3.5 $NIFI_SCRIPT/process_logs.py $NIFI_LOG/log_cat > $NIFI_LOG/temp
#python3.5 ./extract_latencies.py $NIFI_LOG/log_cat > $NIFI_LOG/temp

echo; echo "RESULT"; echo "------------------------------------------"
tail -n 5 $NIFI_LOG/temp; echo "------------------------------------------"; echo

# Ask if you want to save it.
echo;read -p "$SHELL: Do you want to save this log? [y/n]" -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo;echo "$SHELL: Done."
    exit 1
fi

# Save as
while true; do
    echo; read -p "$SHELL: Type a filename: " file_name
    if [ "$file_name" == "" ]; then
        echo "$SHELL: Please name it with non-empty string."
    elif [ -f "$NIFI_RESULTS/$file_name" ]; then
        echo "$SHELL: File exist. Please name it with other name."
    else
        break
    fi
done
cp $NIFI_LOG/temp $NIFI_RESULTS/$file_name
echo "$SHELL: Saving a file as $NIFI_RESULTS/$file_name"

echo;echo "$SHELL: Done."
