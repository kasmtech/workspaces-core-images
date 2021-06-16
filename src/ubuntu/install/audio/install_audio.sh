#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Audio Requirements"
if [ "${DISTRO}" == "centos" ] ; then
  yum install -y curl git
  yum install -y epel-release
  yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
  yum install -y ffmpeg pulseaudio-utils
  yum remove -y pulseaudio-module-bluetooth
else
  apt-get update
  apt-get install -y curl git ffmpeg
fi

cd $STARTUPDIR
mkdir jsmpeg
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_websocket_relay/5b1e1eaa251f7a423a818056e2e8cdb66c17ef98/kasm_websocket_relay_master.5b1e1e.tar.gz | tar xz --strip 1 -C $STARTUPDIR/jsmpeg
chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux
