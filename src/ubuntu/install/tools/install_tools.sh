#!/usr/bin/env bash
set -e

echo "Install some common tools for further installation"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum install -y vim wget net-tools bzip2 ca-certificates bc
elif [[ "${DISTRO}" == @(fedora37|fedora38|oracle8|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf install -y wget net-tools bzip2 tar vim hostname procps-ng bc
elif [ "${DISTRO}" == "opensuse" ]; then
  sed -i 's/download.opensuse.org/mirrorcache-us.opensuse.org/g' /etc/zypp/repos.d/*.repo
  zypper install -yn wget net-tools bzip2 tar vim gzip iputils bc
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache \
    ca-certificates \
    curl \
    gcompat \
    grep \
    libgcc \
    mcookie \
    net-tools \
    openssh-client \
    openssl \
    shadow \
    sudo \
    tar \
    wget \
    bc
else
  apt-get update
  # Update tzdata noninteractive (otherwise our script is hung on user input later).
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
  apt-get install -y vim wget net-tools locales bzip2 wmctrl software-properties-common mesa-utils bc

  echo "generate locales for en_US.UTF-8"
  locale-gen en_US.UTF-8
fi

if [ "$DISTRO" = "ubuntu" ]; then
  #update mesa to latest
  add-apt-repository ppa:kisak/turtle
  apt-get update
  apt full-upgrade -y
fi
