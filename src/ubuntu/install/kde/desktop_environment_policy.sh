#!/bin/bash

# TODO: Find explicit way to determine that KDE is ready
sleep 5

# Disable screen lock
kwriteconfig5 --file kscreenlockerrc --group Daemon --key Autolock false
qdbus org.freedesktop.ScreenSaver /ScreenSaver configure
