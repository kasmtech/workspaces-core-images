#!/usr/bin/env bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir $STARTUPDIR/upload_server
wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/a22519ef70d05fd50099196ff6cb3dd8cb2ed13c/kasm_upload_service_${ARCH}_develop.a22519.tar.gz -O /tmp/kasm_upload_server.tar.gz
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
