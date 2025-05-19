#!/usr/bin/env bash
set -e

if [ "${DISTRO}" == "parrotos6" ]; then
  PARROTEXTRA="-t lory-backports"
fi

echo "Install some common tools for further installation"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum install -y vim wget net-tools bzip2 ca-certificates bc
elif [[ "${DISTRO}" == @(fedora37|fedora38|fedora39|fedora40|fedora41|oracle8|oracle9|rhel9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf install -y wget net-tools bzip2 tar vim hostname procps-ng bc
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn wget net-tools bzip2 tar vim gzip iputils bc
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache \
    ca-certificates \
    curl \
    gcompat \
    grep \
    iproute2-minimal \
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
  ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
  DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
  # Debian (KasmOS) requires a reconfigure because tzdata is already installed
  # On Ubuntu, this is a no-op
  dpkg-reconfigure --frontend noninteractive tzdata

  # software-properties is removed from kali-rolling
  if grep -q "kali-rolling" /etc/os-release; then
    apt-get install ${PARROTEXTRA} -y vim wget net-tools locales bzip2 wmctrl mesa-utils bc
  else
    apt-get install ${PARROTEXTRA} -y vim wget net-tools locales bzip2 wmctrl software-properties-common mesa-utils bc
  fi

  # Install openssh-client on Ubuntu
  if grep -q "ubuntu" /etc/os-release; then
    apt-get install -y openssh-client
  fi

  echo "generate locales for en_US.UTF-8"
  locale-gen en_US.UTF-8
fi

if [ "$DISTRO" = "ubuntu" ] && ! grep -q "24.04" /etc/os-release; then
  #update mesa to latest
  add-apt-repository ppa:kisak/turtle
  apt-get update
  apt full-upgrade -y
elif [ "$DISTRO" = "ubuntu" ] && grep -q "24.04" /etc/os-release; then
  userdel ubuntu
  rm -Rf /home/ubuntu
fi
