#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

COMMIT_ID="82d11b74e05be5175cd4096ad6463f83ded1f532"
BRANCH="develop"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/audio_input
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/${COMMIT_ID}/kasm_audio_input_server_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/audio_input/kasm_audio_input_server.version
