#!/usr/bin/env bash
set -e

echo "Install nss-wrapper to be able to execute image as non-root user"
if [[ "${DISTRO}" == @(centos|oracle7|oracle8) ]] ; then
  if [ "${DISTRO}" == "centos" ]; then
    yum install -y centos-release-scl-rh && yum install -y nss_wrapper
  elif [ "${DISTRO}" == "oracle8" ]; then
    dnf install -y nss_wrapper gettext hostname
    dnf clean all
  else
    yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-rh-2-3.el7.centos.noarch.rpm && yum install -y nss_wrapper
  fi
  if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
    yum install -y gettext
    yum clean all
  fi
elif [[ "${DISTRO}" == "opensuse" ]] ; then
  zypper install -ny nss_wrapper gettext-runtime
  zypper clean --all
  sed -i 's/mirrorcache-us.opensuse.org/download.opensuse.org/g' /etc/zypp/repos.d/*.repo
else
  apt-get update
  apt-get install -y libnss-wrapper gettext
  apt-get clean -y
fi

echo "add 'source generate_container_user' to .bashrc"

# have to be added to hold all env vars correctly
echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc
