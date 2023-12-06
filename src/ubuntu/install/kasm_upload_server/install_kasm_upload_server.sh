#!/usr/bin/env bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir $STARTUPDIR/upload_server
wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/eba9cfa220520e8e041e8cd2e031dc763af41806/kasm_upload_service_amd64_bugfix_KASM-5302_reset_code.eba9cf.tar.gz -O /tmp/kasm_upload_server.tar.gz
#wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/dc82ed90ac44ddd05cbd08ae6968aaabebe0a6fe/kasm_upload_service_${ARCH}_develop.dc82ed.tar.gz -O /tmp/kasm_upload_server.tar.gz
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
