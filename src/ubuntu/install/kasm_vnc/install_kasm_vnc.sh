#!/usr/bin/env bash
set -e

prepare_rpm_repo_dependencies() {
  if [[ "$DISTRO" = "oracle7" ]]; then
    yum-config-manager --enable ol7_optional_latest
  elif [[ "$DISTRO" = "oracle8" ]]; then
    dnf config-manager --set-enabled ol8_codeready_builder
    dnf install -y oracle-epel-release-el8
  fi
}

echo "Install KasmVNC server"
cd /tmp
BUILD_ARCH=$(uname -p)
UBUNTU_CODENAME=""
COMMIT_ID="9a8bfce25fd81a44e815937db72a84399635e4ef"
BRANCH="master" # just use 'release' for a release branch
KASMVNC_VER="1.0.2"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

# Naming scheme is now different between an official release and feature branch
KASM_VER_NAME_PART="${KASMVNC_VER}_${BRANCH}_${COMMIT_ID_SHORT}"
if [[ "${BRANCH}" == "release" ]] ; then
  KASM_VER_NAME_PART="${KASMVNC_VER}"
fi

if [ "${DISTRO}" == "kali" ]  ;
then
    apt-get update
    apt-get install -y sgml-base
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_kali-rolling_${KASM_VER_NAME_PART}_amd64.deb"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_kali-rolling_${KASM_VER_NAME_PART}_arm64.deb"
    fi
elif [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_centos_core_${KASM_VER_NAME_PART}_x86_64.rpm"
elif [[ "${DISTRO}" == "oracle8" ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_8_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_8_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" == "opensuse" ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_opensuse_15_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_opensuse_15_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
else
    UBUNTU_CODENAME=$(grep -Po -m 1 "(?<=_CODENAME=)\w+" /etc/os-release)
    if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_${UBUNTU_CODENAME}_${KASM_VER_NAME_PART}_arm64.deb"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_${UBUNTU_CODENAME}_${KASM_VER_NAME_PART}_amd64.deb"
    fi
fi


prepare_rpm_repo_dependencies
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
    wget "${BUILD_URL}" -O kasmvncserver.rpm
    yum localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
elif [[ "${DISTRO}" == "oracle8" ]] ; then
    wget "${BUILD_URL}" -O kasmvncserver.rpm
    dnf localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
    dnf clean all
elif [[ "${DISTRO}" == "opensuse" ]] ; then
  mkdir -p /etc/pki/tls/private
  wget "${BUILD_URL}" -O kasmvncserver.rpm
  zypper install -y --allow-unsigned-rpm ./kasmvncserver.rpm
  rm kasmvncserver.rpm
  zypper clean --all
else
    wget "${BUILD_URL}" -O kasmvncserver.deb

    apt-get update
    apt-get install -y gettext ssl-cert libxfont2
    apt-get install -y /tmp/kasmvncserver.deb
    rm -f /tmp/kasmvncserver.deb
fi
#mkdir $KASM_VNC_PATH/certs
mkdir -p $KASM_VNC_PATH/www/Downloads
chown -R 0:0 $KASM_VNC_PATH
chmod -R og-w $KASM_VNC_PATH
#chown -R 1000:0 $KASM_VNC_PATH/certs
chown -R 1000:0 $KASM_VNC_PATH/www/Downloads
ln -s $KASM_VNC_PATH/www/index.html $KASM_VNC_PATH/www/vnc.html
