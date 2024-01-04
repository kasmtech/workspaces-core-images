#!/usr/bin/env bash
set -e

prepare_rpm_repo_dependencies() {
  if [[ "$DISTRO" = "oracle7" ]]; then
    yum-config-manager --enable ol7_optional_latest
  elif [[ "$DISTRO" = "oracle8" ]]; then
    dnf config-manager --set-enabled ol8_codeready_builder
    dnf install -y oracle-epel-release-el8
  elif [[ "$DISTRO" = "oracle9" ]]; then
    dnf config-manager --set-enabled ol9_codeready_builder
    dnf install -y oracle-epel-release-el9
  fi
}
#https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/7b442658e13a291b9e5d97b068e98a1d6abff942/kasmvncserver_buster_1.2.1_master_7b4426_amd64.deb
echo "Install KasmVNC server"
cd /tmp
BUILD_ARCH=$(uname -p)
UBUNTU_CODENAME=""
COMMIT_ID="7b442658e13a291b9e5d97b068e98a1d6abff942"
BRANCH="master" # just use 'release' for a release branch
KASMVNC_VER="1.2.1"
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
elif [[ "${DISTRO}" == @(rockylinux8|oracle8|almalinux8) ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_8_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_8_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" == @(rockylinux9|oracle9|almalinux9) ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_9_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_oracle_9_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" == "opensuse" ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_opensuse_15_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_opensuse_15_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" == "fedora37" ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_fedora_thirtyseven_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_fedora_thirtyseven_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" == "fedora38" ]] ; then
    if [[ "$(arch)" =~ ^x86_64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_fedora_thirtyeight_${KASM_VER_NAME_PART}_x86_64.rpm"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_fedora_thirtyeight_${KASM_VER_NAME_PART}_aarch64.rpm"
    fi
elif [[ "${DISTRO}" = @(debian|parrotos5) ]] ; then
    if grep -q bookworm /etc/os-release; then
        if [[ "$(arch)" =~ ^x86_64$ ]] ; then
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_bookworm_${KASM_VER_NAME_PART}_amd64.deb"
        else
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_bookworm_${KASM_VER_NAME_PART}_arm64.deb"
        fi
    else
        if [[ "$(arch)" =~ ^x86_64$ ]] ; then
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_bullseye_${KASM_VER_NAME_PART}_amd64.deb"
        else
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/kasmvncserver_bullseye_${KASM_VER_NAME_PART}_arm64.deb"
        fi
    fi
elif [[ "${DISTRO}" == "alpine" ]] ; then
    if grep -q v3.18 /etc/os-release; then
        if [[ "$(arch)" =~ ^x86_64$ ]] ; then
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/output/alpine_318/kasmvnc.alpine_318_x86_64.tgz"
        else
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/output/alpine_318/kasmvnc.alpine_318_aarch64.tgz"
        fi
    else
        if [[ "$(arch)" =~ ^x86_64$ ]] ; then
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/output/alpine_317/kasmvnc.alpine_317_x86_64.tgz"
        else
            BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${COMMIT_ID}/output/alpine_317/kasmvnc.alpine_317_aarch64.tgz"
        fi
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
elif [[ "${DISTRO}" == @(oracle8|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]] ; then
    wget "${BUILD_URL}" -O kasmvncserver.rpm
    dnf localinstall -y kasmvncserver.rpm
    dnf install -y mesa-dri-drivers
    rm kasmvncserver.rpm
elif [[ "${DISTRO}" == @(fedora37|fedora38) ]] ; then
    dnf install -y xorg-x11-drv-amdgpu xorg-x11-drv-ati
    if [ "${BUILD_ARCH}" == "x86_64" ]; then
        dnf install -y xorg-x11-drv-intel
    fi
    wget "${BUILD_URL}" -O kasmvncserver.rpm
    dnf localinstall -y --allowerasing kasmvncserver.rpm
    dnf install -y mesa-dri-drivers
    rm kasmvncserver.rpm
elif [[ "${DISTRO}" == "opensuse" ]] ; then
    mkdir -p /etc/pki/tls/private
    wget "${BUILD_URL}" -O kasmvncserver.rpm
    zypper install -y \
        libdrm_amdgpu1 \
	libdrm_radeon1
    if [ "${BUILD_ARCH}" == "x86_64" ]; then
        zypper install -y libdrm_intel1
    fi
    zypper install -y --allow-unsigned-rpm ./kasmvncserver.rpm
    rm kasmvncserver.rpm
elif [[ "${DISTRO}" == "alpine" ]] ; then
    apk add --no-cache \
        libgomp \
        libjpeg-turbo \
        libwebp \
        libxfont2 \
        libxshmfence \
        mesa-gbm \
        pciutils-libs \
        perl \
        perl-datetime \
        perl-hash-merge-simple \
        perl-list-moreutils \
        perl-switch \
        perl-try-tiny \
        perl-yaml-tiny \
        perl-datetime \
        perl-datetime-timezone \
        pixman \
        py3-xdg \
        setxkbmap \
        xauth \
        xf86-video-amdgpu \
        xf86-video-ati \
        xf86-video-nouveau \
        xkbcomp \
        xkeyboard-config \
        xterm
    if [ "${BUILD_ARCH}" == "x86_64" ]; then
        apk add --no-cache xf86-video-intel
    fi
    curl -s "${BUILD_URL}" | tar xzvf - -C /
    ln -s /usr/local/share/kasmvnc /usr/share/kasmvnc
    ln -s /usr/local/etc/kasmvnc /etc/kasmvnc
    ln -s /usr/local/lib/kasmvnc /usr/lib/kasmvncserver
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
