#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

COMMIT_ID="e19fbc6d8c6bd0eea88dd20be20e016e1be7024d"
BRANCH="feature_KASM-5378_recording_errata"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/recorder
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_recorder_service/${COMMIT_ID}/kasm_recorder_service_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/recorder/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/recorder/kasm_recorder_service.version
