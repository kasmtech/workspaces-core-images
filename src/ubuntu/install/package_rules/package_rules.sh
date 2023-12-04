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
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora37|fedora38|oracle8|oracle9|rockylinux8|rockylinux9) ]]; then
  rm -f /etc/rpm/macros.image-language-conf
elif [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  sed -i \
    '/override_install_langs/d' \
    /etc/yum.conf
  yum reinstall -y \
    glibc-common
fi

echo "Upgrading packages from upstream base image"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum update -y
elif [[ "${DISTRO}" == @(fedora37|fedora38|oracle8|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf upgrade -y --refresh
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper --non-interactive patch --auto-agree-with-licenses
elif [ "${DISTRO}" == "alpine" ]; then
  apk update
  apk add --upgrade apk-tools
  apk upgrade --available
else
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
fi