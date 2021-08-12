#!/usr/bin/env bash
set -e

echo -e "\n------------------ Xfce4 window manager startup------------------"

if [ "${START_XFCE4}" == "1" ] ;
    then
        echo "Starting XFCE"
        /usr/bin/startxfce4 --replace &
    else
        echo "Skipping XFCE Startup"
    fi
