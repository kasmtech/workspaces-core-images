#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Installing ttf-wqy-zenhei"
if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum install -y wqy-zenhei-fonts
elif [[ "${DISTRO}" == @(fedora37|oracle8|oracle9|rockylinux9|rockylinux8|almalinux9|almalinux8) ]]; then
  dnf install -y google-noto-sans-fonts
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -ny wqy-zenhei-fonts
  zypper clean --all
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache \
    font-noto \
    font-noto-cjk
else
  apt-get update
  apt-get install -y ttf-wqy-zenhei
  apt-get autoclean 
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi
