#!/usr/bin/env bash
set -e

echo "Install some common tools for further installation"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum install -y vim wget net-tools bzip2 python3 ca-certificates
elif [ "${DISTRO}" == "oracle8" ]; then
  dnf install -y wget net-tools bzip2 python3 tar vim hostname
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  sed -i 's/download.opensuse.org/mirrorcache-us.opensuse.org/g' /etc/zypp/repos.d/*.repo
  zypper install -yn wget net-tools bzip2 python3 tar vim gzip iputils
  zypper clean --all
else
  apt-get update
  # Update tzdata noninteractive (otherwise our script is hung on user input later).
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
  apt-get install -y vim wget net-tools locales bzip2 wmctrl software-properties-common mesa-utils 
  apt-get clean -y

  echo "generate locales für en_US.UTF-8"
  locale-gen en_US.UTF-8
fi

if [ "$DISTRO" = "ubuntu" ]; then
  #update mesa to latest
  add-apt-repository ppa:kisak/turtle
  apt full-upgrade -y
fi
