#!/bin/bash

# Set any bookmarks passed from env
if [ ! -z ${CLOUD_MOUNTS+x} ]; then
  mkdir -p $HOME/.config/gtk-3.0/
  touch $HOME/.config/gtk-3.0/bookmarks
  IFS=,
  for CLOUD_MOUNT in ${CLOUD_MOUNTS}; do
    LOCAL_PATH=$(echo "${CLOUD_MOUNT}" | awk -F'|' '{print $1}')
    ICON=$(echo "${CLOUD_MOUNT}" | awk -F'|' '{print $2}')
    if [ -d "${LOCAL_PATH}" ] && ! grep -qx "file://${LOCAL_PATH}" $HOME/.config/gtk-3.0/bookmarks; then
      echo "file://${LOCAL_PATH}" >> $HOME/.config/gtk-3.0/bookmarks
      gio set -t stringv "${LOCAL_PATH}" metadata::emblems "${ICON}-emblem"
    fi
  done
fi
