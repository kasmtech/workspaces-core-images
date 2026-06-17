#!/usr/bin/env bash
set -ex

if [[ "${DISTRO}" == "ubuntu" ]] ; then
  sed -i \
    '/locale/d' \
    /etc/dpkg/dpkg.cfg.d/excludes
elif [[ "${DISTRO}" == "debian" ]] ; then
  sed -i \
    '/locale/d' \
    /etc/dpkg/dpkg.cfg.d/docker
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora42|fedora43|oracle8|oracle9|rhel9|rockylinux8|rockylinux9) ]]; then
  rm -f /etc/rpm/macros.image-language-conf
fi

echo "Upgrading packages from upstream base image"
if [[ "${DISTRO}" == @(fedora42|fedora43|oracle8|oracle9|rhel9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf upgrade -y --refresh
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper --non-interactive patch --auto-agree-with-licenses
elif [ "${DISTRO}" == "alpine" ]; then
  apk update
  apk add --upgrade apk-tools
  apk upgrade --available
elif [[ "${DISTRO}" == "parrotos7" ]]; then
  sed -i 's|https://deb.parrot.sh/parrot|https://mirrors.mit.edu/parrot|g' /etc/apt/sources.list.d/parrot.list
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
else
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
fi
