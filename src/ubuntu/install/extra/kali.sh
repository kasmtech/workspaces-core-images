#!/usr/bin/env bash
set -ex

apt-get update

apt-get install -y procps  dbus-x11

# Install the standard default kali tools
#   https://tools.kali.org/kali-metapackages
# kali-linux-default use mlocate which breaks plocate
apt-get remove -y plocate
apt-get install -y kali-linux-default

# Kali  installs firefox by default. We need to update this install to utilze the system's certificate store
#   in order for web filtering to work

apt-get install -y p11-kit-modules

rm -rf /usr/lib/firefox-esr/libnssckbi.so
ln /usr/lib/$(arch)-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox-esr/libnssckbi.so
