#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

COMMIT_ID="717ef2e2e502983d06372d77939d3fc654dd8306"
BRANCH="develop"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir -p $STARTUPDIR/gamepad
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_gamepad_server/${COMMIT_ID}/kasm_gamepad_server_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/gamepad/


SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_PATH="$(realpath $SCRIPT_PATH)"

mkdir -p /usr/share/extra/icons/
cp ${SCRIPT_PATH}/gamepad.svg /usr/share/extra/icons/gamepad.svg
