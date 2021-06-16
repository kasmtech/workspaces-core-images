#!/usr/bin/env bash
set -e

echo "Install nss-wrapper to be able to execute image as non-root user"
if [ "${DISTRO}" == "centos" ] ; then
  yum install -y centos-release-scl-rh && yum install -y nss_wrapper
  yum install -y gettext
  yum clean all
else
  apt-get update
  apt-get install -y libnss-wrapper gettext
  apt-get clean -y
fi

echo "add 'source generate_container_user' to .bashrc"

# have to be added to hold all env vars correctly
echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc
