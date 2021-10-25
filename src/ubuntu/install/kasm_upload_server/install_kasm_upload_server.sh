#!/usr/bin/env bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir $STARTUPDIR/upload_server
wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/839a3b9ce63569aaee4f7d62bd31ffb20184a393/kasm_upload_service_${DISTRO/kali/ubuntu}_${ARCH}_develop.839a3b.tar.gz -O /tmp/kasm_upload_server.tar.gz
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
