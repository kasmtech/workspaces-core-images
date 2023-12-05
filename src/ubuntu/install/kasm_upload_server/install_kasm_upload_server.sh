#!/usr/bin/env bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir $STARTUPDIR/upload_server
wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/f3b6f35a3db91dc61cd346a4f39b0c7c71cd006f/kasm_upload_service_${ARCH}_bugfix_KASM-5283_upload_filename_sanitization.f3b6f3.tar.gz -O /tmp/kasm_upload_server.tar.gz
#wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/dc82ed90ac44ddd05cbd08ae6968aaabebe0a6fe/kasm_upload_service_${ARCH}_develop.dc82ed.tar.gz -O /tmp/kasm_upload_server.tar.gz
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
