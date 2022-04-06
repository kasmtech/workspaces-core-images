#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Installing ttf-wqy-zenhei"
if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum install -y wqy-zenhei-fonts
elif [ "${DISTRO}" == "oracle8" ]; then
  dnf install -y google-noto-sans-fonts
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -ny wqy-zenhei-fonts
  zypper clean --all
else
  apt-get install -y ttf-wqy-zenhei
fi
