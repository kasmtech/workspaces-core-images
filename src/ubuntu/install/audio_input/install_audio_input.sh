#!/usr/bin/env bash
### every exit != 0 fails the script
set -e
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir -p $STARTUPDIR/audio_input
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/3b599f999efdb349969cf607b6ed636c4501108d/kasm_audio_input_server_${DISTRO/kali/ubuntu}_${ARCH}_develop.3b599f.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/