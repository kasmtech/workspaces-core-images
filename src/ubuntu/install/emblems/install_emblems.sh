#!/bin/bash
set -e

# Icon list to ingest
IFS=$'\n'
icons='https://upload.wikimedia.org/wikipedia/commons/b/bc/Amazon-S3-Logo.svg|s3
https://upload.wikimedia.org/wikipedia/commons/6/60/Nextcloud_Logo.svg|nextcloud
https://upload.wikimedia.org/wikipedia/commons/3/3c/Microsoft_Office_OneDrive_%282019%E2%80%93present%29.svg|onedrive
https://upload.wikimedia.org/wikipedia/commons/1/12/Google_Drive_icon_%282020%29.svg|gdrive
https://upload.wikimedia.org/wikipedia/commons/7/78/Dropbox_Icon.svg|dropbox
https://kasm-ci.s3.amazonaws.com/kasm.svg|kasm'

# Download icons and add to cache
mkdir -p /usr/share/icons/hicolor/scalable/emblems
for icon in $icons; do
  URL=$(echo "${icon}" | awk -F'|' '{print $1}')
  NAME=$(echo "${icon}" | awk -F'|' '{print $2}')
  curl -o /usr/share/icons/hicolor/scalable/emblems/${NAME}-emblem.svg -L "${URL}"
  echo "[Icon Data]" >> /usr/share/icons/hicolor/scalable/emblems/${NAME}-emblem.icon
  echo "DisplayName=${NAME}-emblem" >> /usr/share/icons/hicolor/scalable/emblems/${NAME}-emblem.icon
done
gtk-update-icon-cache -f /usr/share/icons/hicolor

# Support dynamic icons on init
cat >>/etc/xdg/autostart/emblems.desktop<<EOL
[Desktop Entry]
Type=Application
Name=Folder Emblems
Exec=/dockerstartup/emblems.sh
EOL
chmod +x /etc/xdg/autostart/emblems.desktop
