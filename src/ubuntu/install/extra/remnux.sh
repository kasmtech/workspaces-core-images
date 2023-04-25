#!/usr/bin/env bash
set -xe


# Install remnux base
apt-get update
apt-get install -y wget gnupg git
if $(grep -q Focal /etc/os-release); then
  wget -nv -O - https://repo.saltproject.io/py3/ubuntu/20.04/amd64/latest/salt-archive-keyring.gpg | apt-key add -
  echo deb [arch=amd64] https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3004 focal main > /etc/apt/sources.list.d/saltstack.list
elif $(grep -q Bionic /etc/os-release); then
  wget -nv -O - https://repo.saltproject.io/py3/ubuntu/18.04/amd64/latest/salt-archive-keyring.gpg | apt-key add -
  echo deb [arch=amd64] https://repo.saltproject.io/py3/ubuntu/18.04/amd64/3004 bionic main > /etc/apt/sources.list.d/saltstack.list
fi
apt-get update
apt-get install -y salt-common 
git clone https://github.com/REMnux/salt-states.git /srv/salt
