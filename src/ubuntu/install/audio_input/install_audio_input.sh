#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir -p $STARTUPDIR/audio_input
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/58c23638d7bc7f9c90799d76a957cb02bfee153e/kasm_audio_input_server_${ARCH}_develop.58c236.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/
