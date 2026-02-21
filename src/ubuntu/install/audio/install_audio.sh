#!/usr/bin/env bash
### every exit != 0 fails the script
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
echo "Install Audio Requirements"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum install -y curl git
  yum install -y epel-release
  yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
  yum install -y ffmpeg pulseaudio-utils
  sed -i '/Bluetooth/,+7d' /etc/pulse/default.pa
elif [ "${DISTRO}" == "oracle8" ]; then
  dnf install -y curl git
  dnf config-manager --set-enabled ol8_codeready_builder
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
  dnf install -y ffmpeg pulseaudio-utils
elif [[ "${DISTRO}" == @(oracle9|rhel9) ]]; then
  dnf install -y --allowerasing curl git
  if [[ "${DISTRO}" == "oracle9" ]]; then
    dnf config-manager --set-enabled ol9_codeready_builder
  fi
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [[ "${DISTRO}" == @(rockylinux9|almalinux9) ]]; then
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [[ "${DISTRO}" == @(rockylinux8|almalinux8) ]]; then
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [ "${DISTRO}" == "fedora37" ]; then
  dnf install -y curl git
  dnf localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-37.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [ "${DISTRO}" == "fedora38" ]; then
  dnf install -y curl git
  dnf localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-38.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [ "${DISTRO}" == "fedora39" ]; then
  dnf install -y curl git
  dnf localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-39.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [ "${DISTRO}" == "fedora40" ]; then
  dnf install -y curl git
  dnf localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-40.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [ "${DISTRO}" == "fedora41" ]; then
  dnf install -y curl git
  dnf-3 localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-41.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -ny curl git
  zypper install -yn ffmpeg pulseaudio-utils
elif [ "${DISTRO}" == "alpine" ]; then
  if grep -q v3.19 /etc/os-release || grep -q v3.20 /etc/os-release || grep -q v3.21 /etc/os-release; then
    apk add --no-cache \
      ffmpeg \
      ffplay \
      git \
      pulseaudio \
      pulseaudio-utils
  else
    apk add --no-cache \
      ffmpeg \
      git \
      pulseaudio \
      pulseaudio-utils
  fi
else
  apt-get update
  apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    git \
    pulseaudio \
    pulseaudio-utils
fi

mkdir -p /var/run/pulse

WS_COMMIT_ID="f7efb82dc59a02d1b99e2e2b3c6d127dc548ba72"
WS_BRANCH="develop"
WS_COMMIT_ID_SHORT=$(echo "${WS_COMMIT_ID}" | cut -c1-6)

cd $STARTUPDIR
mkdir jsmpeg
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_websocket_relay/${WS_COMMIT_ID}/kasm_websocket_relay_${ARCH}_${WS_BRANCH}.${WS_COMMIT_ID_SHORT}.tar.gz | tar xz --strip 1 -C $STARTUPDIR/jsmpeg
chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux
