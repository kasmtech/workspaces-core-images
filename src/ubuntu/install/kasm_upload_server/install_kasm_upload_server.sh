#!/usr/bin/env bash
set -ex

if [ "${DISTRO}" == "oracle7" ]; then
  DISTRO=centos
elif [ "${DISTRO}" == "oracle8" ]; then
  DISTRO=oracle
fi

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
mkdir $STARTUPDIR/upload_server
wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/594ff9c24baa89477ef4fc937933e11529924cce/kasm_upload_service_${DISTRO/kali/ubuntu}_${ARCH}_develop.594ff9.tar.gz -O /tmp/kasm_upload_server.tar.gz
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
