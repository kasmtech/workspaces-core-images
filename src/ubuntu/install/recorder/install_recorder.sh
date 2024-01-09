#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

COMMIT_ID="75cf09992503e77a94b5f5c4deba7fc1daad4f5a"
BRANCH="bugfix_KASM-5419_fix_session_recorder_on_all_distros"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/recorder
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_recorder_service/${COMMIT_ID}/kasm_recorder_service_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/recorder/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/recorder/kasm_recorder_service.version
