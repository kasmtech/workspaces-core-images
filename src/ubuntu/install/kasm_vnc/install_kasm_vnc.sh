#!/usr/bin/env bash
set -e

install_libjpeg_turbo() {
    local libjpeg_deb=libjpeg-turbo.deb

    wget 'https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/dbc376940f971d62451c219f3a354bf6639e7595/output/bionic/libjpeg-turbo_2.1.2_amd64.deb' -O "$libjpeg_deb"
    apt-get install -y "./$libjpeg_deb"
    rm "$libjpeg_deb"
}

echo "Install KasmVNC server"
cd /tmp

if [ "${DISTRO}" == "kali" ]  ;
then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/d9ceb72c2e982772f5827bb9b9325ff8ad73be5a/kasmvncserver_kali-rolling_0.9.3_feature_KASM-1913_webp_tweaks_d9ceb7_amd64.deb"
elif [ "${DISTRO}" == "centos" ] ; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/d9ceb72c2e982772f5827bb9b9325ff8ad73be5a/kasmvncserver_centos_0.9.3_feature_KASM-1913_webp_tweaks_d9ceb7_x86_64.rpm"
elif [ "$DISTRO" == "ubuntu" ]; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/d9ceb72c2e982772f5827bb9b9325ff8ad73be5a/kasmvncserver_bionic_0.9.3_feature_KASM-1913_webp_tweaks_d9ceb7__libjpeg-turbo-latest_amd64.deb"
else
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/d9ceb72c2e982772f5827bb9b9325ff8ad73be5a/kasmvncserver_bionic_0.9.3_feature_KASM-1913_webp_tweaks_d9ceb7_amd64.deb"
fi


if [ "${DISTRO}" == "centos" ] ; then
    wget "${BUILD_URL}" -O kasmvncserver.rpm

    yum localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
else
    if [ "$DISTRO" = "ubuntu" ]; then
        install_libjpeg_turbo
    fi

    wget "${BUILD_URL}" -O kasmvncserver.deb

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
