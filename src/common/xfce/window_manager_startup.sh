#!/usr/bin/env bash
set -e

echo -e "\n------------------ Xfce4 window manager startup------------------"

if [ "${START_XFCE4}" == "1" ] ;
    then
	if [ -f /usr/bin/vglrun ] && [ -d /dev/dri ]; then
            echo "Starting XFCE with VirtualGL"
	    DISPLAY=:1 /usr/bin/vglrun -d /dev/dri/card0 /usr/bin/startxfce4 --replace &
	else
            echo "Starting XFCE"
            /usr/bin/startxfce4 --replace &
	fi
    else
        echo "Skipping XFCE Startup"
    fi
