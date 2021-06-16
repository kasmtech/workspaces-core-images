#!/usr/bin/env bash
set -xe

# Remnux installs firefox by default. We need to update this install to utilze the system's certificate store
#   in order for web filtering to work

apt-get install -y p11-kit-modules

rm /usr/lib/firefox/libnssckbi.so
ln /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox/libnssckbi.so


# Remnux includes bluetooth drivers which try to autoload causing pluse audio to fail
sed -i "s/module-bluetooth-discover.so/module-bluetooth-discover.so.ignore/g"  /etc/pulse/default.pa
