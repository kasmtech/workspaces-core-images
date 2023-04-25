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
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora37|oracle8|oracle9|rockylinux8|rockylinux9) ]]; then
  rm -f /etc/rpm/macros.image-language-conf
elif [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  sed -i \
    '/override_install_langs/d' \
    /etc/yum.conf
  yum reinstall -y \
    glibc-common
fi
