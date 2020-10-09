IP=`hostname -i`
export NIFI_HOME="/home/ubuntu/jarvis-nifi"
export NIFI_BIN="$NIFI_HOME/bin"
export NIFI_SCRIPTS="$NIFI_HOME/scripts"
export NIFI_RESULTS="$NIFI_HOME/results"
export NIFI_CONF="$NIFI_HOME/conf"
export FINAL_QUEUE_ID=1cebae29-016f-1000-96fd-971ebcf4d231
export LOG_PROCESSOR_ID=d02bb153-016c-1000-3bed-7ffc10e019d1

alias start_nifi='sudo rm -rf $NIFI_HOME/content_repository/* $NIFI_HOME/provenance_repository/* $NIFI_HOME/flowfile_repository/* $NIFI_HOME/state/local/* $NIFI_HOME/logs/*;sudo $NIFI_BIN/nifi.sh start'
alias test='curl "http://$IP:8080/nifi-api/access/config" -X GET; echo'
alias queue='curl "http://$IP:8080/nifi-api/connections/$FINAL_QUEUE_ID" -X GET | grep flowFilesQueued; echo'
alias stop_nifi='sudo $NIFI_BIN/nifi.sh stop'
alias restart_nifi='stop_nifi && start_nifi'
alias set_conf='sed -i s/nifi.remote.input.host=.*/nifi.remote.input.host=$IP/ $NIFI_CONF/nifi.properties;sed -i s/nifi.web.http.host=.*/nifi.web.http.host=$IP/ $NIFI_CONF/nifi.properties'
alias ga='git add'
alias gcmsg='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gst='git status'
