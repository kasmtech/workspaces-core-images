#!/usr/bin/env bash
set -e

echo -e "\n------------------ Xfce4 window manager startup------------------"

### disable screen saver and power management
xset -dpms &
xset s noblank &
xset s off &

if [ "${START_XFCE4}" == "1" ] ;
    then
        echo "Starting XFCE"
        /usr/bin/startxfce4 --replace &
    else
        echo "Skipping XFCE Startup"
    fi
