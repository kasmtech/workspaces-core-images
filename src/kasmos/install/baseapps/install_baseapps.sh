#!/bin/bash

# Remove unneeded apps
apt remove -y libnotify4

# Remove menu shortcuts for stuff we don't care to show the user, but don't want to uninstall
rm /usr/share/applications/vim.desktop
rm /usr/share/applications/org.kde.plasma.emojier.desktop
rm /usr/share/applications/kvantummanager.desktop

# Rename the title of some applications
sed -i 's#Name=KFind#Name=Find#' /usr/share/applications/org.kde.kfind.desktop
sed -r -i 's#Name(\[\w+\])?=gedit#Name\1=Editor#g' /usr/share/applications/org.gnome.gedit.desktop

# Download Base Elementory applications compiled by Kasm
# https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_desktop_apps/66826216f0024f5455d18d241dc3e44adbf2c41c/calculator_2.0.3-1_amd64.deb
BASEURL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_desktop_apps"
COMMITID="3c732e03a9e755aaa1b69f3d56a69964ddf8b8d5"
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')


APPS=("calculator_2.0.3-1" "calendar_7.0.0-1" "camera_6.2.2-1" "music_7.0.0-1" "terminal_6.1.2-1" "filemanager_6.5.3-1")

cd $INST_SCRIPTS/baseapps/ 
for app in ${APPS[@]}; do
	wget "${BASEURL}/${COMMITID}/${app}_${ARCH}.deb"
	apt install -y ./${app}_${ARCH}.deb
done

# Install base apt apps
apt update
apt install -y gedit evince shotwell mpv

# Hide stuff in the menu that we don't want there
rm -f /usr/share/applications/vim.desktop
rm -f /usr/share/applications/org.kde.plasma.emojier.desktop
rm -f /usr/share/applications/kvantummanager.desktop

# Add Custom icons
cp $INST_SCRIPTS/baseapps/videos.svg /usr/share/icons/hicolor/scalable/apps/

# Customize desktop menu shortcuts
sed -i 's#Name=KFind#Name=Find#' /usr/share/applications/org.kde.kfind.desktop
sed -r -i 's#Name(\[\w+\])?=gedit#Name\1=Editor#g' /usr/share/applications/org.gnome.gedit.desktop
sed -r -i 's#Name(\[\w+\])?=[Ss]hotwell#Name\1=Photos#g' /usr/share/applications/shotwell.desktop
sed -r -i 's#Icon=.+#Icon=videos#' /usr/share/applications/mpv.desktop
sed -r -i 's#Name(\[\w+\])?=.+#Name\1=Videos#g' /usr/share/applications/mpv.desktop
sed -r -i 's#Categories=.+#Categories=System;#' /usr/share/applications/org.kde.kdeconnect.app.desktop
sed -r -i 's#Categories=.+#Categories=System;#' /usr/share/applications/org.kde.kdeconnect.sms.desktop
sed -r -i 's#Categories=.+#Categories=System;#' /usr/share/applications/org.kde.kdeconnect_open.desktop
