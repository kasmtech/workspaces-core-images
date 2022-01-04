#!/usr/bin/env bash
set -e

echo -e "\n------------------ Xfce4 window manager startup------------------"

if [ "${START_XFCE4}" == "1" ] ; then
    if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "${KASM_EGL_CARD}" ] && [ ! -z "${KASM_RENDERD}" ] && [ -O "${KASM_RENDERD}" ] && [ -O "${KASM_EGL_CARD}" ] ; then
	echo "Starting XFCE with VirtualGL using EGL device ${KASM_EGL_CARD}"
        DISPLAY=:1 /opt/VirtualGL/bin/vglrun -d "${KASM_EGL_CARD}" /usr/bin/startxfce4 --replace &
    else
        echo "Starting XFCE"
        /usr/bin/startxfce4 --replace &
    fi
else
    echo "Skipping XFCE Startup"
fi
