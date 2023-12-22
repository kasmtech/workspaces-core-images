#!/bin/bash

action=$1

pid=$(pgrep -f '^/dockerstartup/recorder/kasm_recorder_service')

case $action in
  "stop"|"pause")
    if [ -z "$pid" ]; then
        echo "No recording process found."
        exit 0
    fi

    kill -s SIGINT $pid
    while [ ! -f "/tmp/kasm_recorder.ack" ]; do
      sleep 1
    done
    ;;
  "resume")
    if [ ! -z "$pid" ]; then
        echo "Recording process already running."
        exit 0
    fi
    kill `pgrep -f "kasm_recorder_startup.sh"`
    /dockerstartup/kasm_recorder_startup.sh &
    ;;
  *)
    echo "Usage: $0 {stop|pause|resume}"
    exit 1
    ;;
esac