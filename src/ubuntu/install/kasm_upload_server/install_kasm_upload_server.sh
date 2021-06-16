#!/usr/bin/env bash
set -ex

mkdir $STARTUPDIR/upload_server
if [ -f /etc/centos-release ]; then
  wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/7a9ab9203b5b16502349bcf8bd8be1527d5e6cad/kasm_upload_service_centos_1.2.0.7a9ab9.tar.gz -O /tmp/kasm_upload_server.tar.gz
else
  wget --quiet https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_upload_service/742b7f4ba521ee89969d2eddfbda0e7bd619944d/kasm_upload_service_1.2.0.742b7f.tar.gz -O /tmp/kasm_upload_server.tar.gz
fi
tar -xvf /tmp/kasm_upload_server.tar.gz -C $STARTUPDIR/upload_server
rm /tmp/kasm_upload_server.tar.gz
