#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

if [ "${DISTRO}" == "oracle7" ]; then
  DISTRO=centos
elif [ "${DISTRO}" == "oracle8" ]; then
  DISTRO=oracle
fi

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir -p $STARTUPDIR/audio_input
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/2c031a71a9ed0bace8ea2ad11238535820c45180/kasm_audio_input_server_${DISTRO/kali/ubuntu}_${ARCH}_develop.2c031a.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/
