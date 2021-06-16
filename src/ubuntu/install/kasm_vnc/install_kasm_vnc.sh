#!/usr/bin/env bash
set -e

echo "Install KasmVNC server"
cd /tmp

if [ "${DISTRO}" == "kali" ]  ;
then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/9144045718b7519088aaaf605001fa3d34f92b34/kasmvncserver_kali-rolling_0.9.3_master_914404_amd64.deb"
elif [ "${DISTRO}" == "centos" ] ; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/9144045718b7519088aaaf605001fa3d34f92b34/kasmvncserver_centos_core_0.9.3_master_914404_x86_64.rpm"
else
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/9144045718b7519088aaaf605001fa3d34f92b34/kasmvncserver_bionic_0.9.3_master_914404_amd64.deb"
fi


if [ "${DISTRO}" == "centos" ] ; then
    wget $BUILD_URL -O kasmvncserver.rpm

    yum localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
else
    wget $BUILD_URL -O kasmvncserver.deb

    apt-get update
    apt-get install -y gettext ssl-cert
    dpkg -i /tmp/kasmvncserver.deb
    apt-get -yf install
    rm -f /tmp/kasmvncserver.deb
fi
#mkdir $KASM_VNC_PATH/certs
mkdir -p $KASM_VNC_PATH/www/Downloads
chown -R 0:0 $KASM_VNC_PATH
chmod -R og-w $KASM_VNC_PATH
#chown -R 1000:0 $KASM_VNC_PATH/certs
chown -R 1000:0 $KASM_VNC_PATH/www/Downloads
ln -s $KASM_VNC_PATH/www/index.html $KASM_VNC_PATH/www/vnc.html
