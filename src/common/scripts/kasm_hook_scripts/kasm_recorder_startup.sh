#!/bin/bash
set -e

mkdir -p /opt/kasm/recordings
chown kasm-recorder:kasm-recorder /opt/kasm/recordings
chmod 700 /opt/kasm/recordings

# wait until X display is avaiable and allow the recorder to connect to it
while ! xhost +SI:localuser:kasm-recorder 2>/dev/null; do
    sleep 1
done

rm -rf /tmp/kasm_recorder.ack

while [ ! -f "/tmp/kasm_recorder.ack" ]; do
    runuser -m kasm-recorder -c "$STARTUPDIR/recorder/kasm_recorder_service --debug 1 --directory /opt/kasm/recordings/ --log /tmp/recorder.log" || true
    sleep 1
done
