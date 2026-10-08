#!/usr/bin/env bash
set -e

if [ "${DISTRO}" == "parrotos7" ]; then
  PARROTEXTRA="-t echo-backports"
fi

ARCH="$(uname -m)"
INSTALL_INTEL_VA_DRIVERS="false"
if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "amd64" ]]; then
  INSTALL_INTEL_VA_DRIVERS="true"
fi

install_optional_pkg() {
  local pkg_mgr="$1"
  local pkg="$2"
  local install_cmd="$3"
  if ! eval "${install_cmd}"; then
    echo "WARN: Package '${pkg}' is not available for ${DISTRO} (${pkg_mgr}); continuing"
  fi
}

install_first_available_pkg() {
  local pkg_mgr="$1"
  local install_prefix="$2"
  shift 2
  local pkg
  for pkg in "$@"; do
    if eval "${install_prefix} ${pkg}"; then
      return 0
    fi
  done
  echo "WARN: None of the equivalent packages are available for ${DISTRO} (${pkg_mgr}): $*; continuing"
  return 0
}

echo "Install some common tools for further installation"
if [[ "${DISTRO}" == @(fedora42|fedora43|oracle8|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf install -y wget net-tools bzip2 tar vim hostname procps-ng bc vulkan-tools
  yum install -y vim wget net-tools bzip2 ca-certificates bc
  install_first_available_pkg "yum" "yum install -y" mesa-demos mesa-utils
  install_first_available_pkg "yum" "yum install -y" libva-utils vainfo
  install_first_available_pkg "yum" "yum install -y" mesa-va-drivers mesa-dri-drivers
  install_optional_pkg "yum" "vulkan-tools" "yum install -y vulkan-tools"
  install_optional_pkg "yum" "mesa-vulkan-drivers" "yum install -y mesa-vulkan-drivers"
  install_optional_pkg "yum" "xorg-x11-drv-amdgpu" "yum install -y xorg-x11-drv-amdgpu"
  install_optional_pkg "yum" "xorg-x11-drv-ati" "yum install -y xorg-x11-drv-ati"
  install_first_available_pkg "yum" "yum install -y" libdrm-amdgpu libdrm_amdgpu1
  install_first_available_pkg "yum" "yum install -y" libdrm-radeon libdrm_radeon1
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_first_available_pkg "yum" "yum install -y" intel-media-driver intel-media-va-driver
    install_first_available_pkg "yum" "yum install -y" libva-intel-driver i965-va-driver
  fi
elif [[ "${DISTRO}" == @(fedora37|fedora38|fedora39|fedora40|fedora41|fedora42|fedora43|oracle8|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf install -y wget net-tools bzip2 tar vim hostname procps-ng bc
  install_first_available_pkg "dnf" "dnf install -y" mesa-demos mesa-utils
  install_first_available_pkg "dnf" "dnf install -y" libva-utils vainfo
  install_first_available_pkg "dnf" "dnf install -y" mesa-va-drivers mesa-dri-drivers
  install_optional_pkg "dnf" "vulkan-tools" "dnf install -y vulkan-tools"
  install_optional_pkg "dnf" "mesa-vulkan-drivers" "dnf install -y mesa-vulkan-drivers"
  install_optional_pkg "dnf" "xorg-x11-drv-amdgpu" "dnf install -y xorg-x11-drv-amdgpu"
  install_optional_pkg "dnf" "xorg-x11-drv-ati" "dnf install -y xorg-x11-drv-ati"
  install_first_available_pkg "dnf" "dnf install -y" libdrm-amdgpu libdrm_amdgpu1
  install_first_available_pkg "dnf" "dnf install -y" libdrm-radeon libdrm_radeon1
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_first_available_pkg "dnf" "dnf install -y" intel-media-driver intel-media-va-driver
    install_first_available_pkg "dnf" "dnf install -y" libva-intel-driver i965-va-driver
  fi
elif [[ "${DISTRO}" == @(rhel9) ]]; then
  dnf install -y wget net-tools bzip2 tar vim hostname procps-ng bc
  install_first_available_pkg "dnf" "dnf install -y" mesa-demos mesa-utils
  install_first_available_pkg "dnf" "dnf install -y" libva-utils vainfo
  install_first_available_pkg "dnf" "dnf install -y" mesa-va-drivers mesa-dri-drivers
  install_optional_pkg "dnf" "vulkan-tools" "dnf install -y vulkan-tools"
  install_optional_pkg "dnf" "mesa-vulkan-drivers" "dnf install -y mesa-vulkan-drivers"
  install_optional_pkg "dnf" "xorg-x11-drv-amdgpu" "dnf install -y xorg-x11-drv-amdgpu"
  install_optional_pkg "dnf" "xorg-x11-drv-ati" "dnf install -y xorg-x11-drv-ati"
  install_first_available_pkg "dnf" "dnf install -y" libdrm-amdgpu libdrm_amdgpu1
  install_first_available_pkg "dnf" "dnf install -y" libdrm-radeon libdrm_radeon1
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_first_available_pkg "dnf" "dnf install -y" intel-media-driver intel-media-va-driver
    install_first_available_pkg "dnf" "dnf install -y" libva-intel-driver i965-va-driver
  fi
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn wget net-tools bzip2 tar vim gzip iputils bc
  install_first_available_pkg "zypper" "zypper install -yn" Mesa-demos mesa-utils Mesa-demo-x
  install_first_available_pkg "zypper" "zypper install -yn" libva-utils vainfo
  install_first_available_pkg "zypper" "zypper install -yn" Mesa-libva mesa-va-drivers
  install_optional_pkg "zypper" "vulkan-tools" "zypper install -yn vulkan-tools"
  install_first_available_pkg "zypper" "zypper install -yn" libdrm_amdgpu1 libdrm-amdgpu1
  install_first_available_pkg "zypper" "zypper install -yn" libdrm_radeon1 libdrm-radeon1
  install_optional_pkg "zypper" "xf86-video-amdgpu" "zypper install -yn xf86-video-amdgpu"
  install_optional_pkg "zypper" "xf86-video-ati" "zypper install -yn xf86-video-ati"
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_first_available_pkg "zypper" "zypper install -yn" intel-media-driver intel-media-va-driver
    install_first_available_pkg "zypper" "zypper install -yn" libva-intel-driver i965-va-driver
  fi
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache \
    ca-certificates \
    curl \
    gcompat \
    grep \
    iproute2-minimal \
    libgcc \
    mcookie \
    net-tools \
    openssh-client \
    openssl \
    shadow \
    sudo \
    tar \
    wget \
    bc
  install_first_available_pkg "apk" "apk add --no-cache" mesa-demos mesa-utils
  install_first_available_pkg "apk" "apk add --no-cache" libva-utils vainfo
  install_first_available_pkg "apk" "apk add --no-cache" mesa-va-gallium mesa-va-drivers
  install_optional_pkg "apk" "vulkan-tools" "apk add --no-cache vulkan-tools"
  install_optional_pkg "apk" "mesa-vulkan-radeon" "apk add --no-cache mesa-vulkan-radeon"
  install_optional_pkg "apk" "xf86-video-amdgpu" "apk add --no-cache xf86-video-amdgpu"
  install_optional_pkg "apk" "xf86-video-ati" "apk add --no-cache xf86-video-ati"
  install_first_available_pkg "apk" "apk add --no-cache" libdrm-amdgpu libdrm_amdgpu1
  install_first_available_pkg "apk" "apk add --no-cache" libdrm-radeon libdrm_radeon1
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_first_available_pkg "apk" "apk add --no-cache" intel-media-driver intel-media-va-driver
    install_first_available_pkg "apk" "apk add --no-cache" libva-intel-driver i965-va-driver
  fi
else
  apt-get update
  # Update tzdata noninteractive (otherwise our script is hung on user input later).
  ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
  DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
  # Debian (KasmOS) requires a reconfigure because tzdata is already installed
  # On Ubuntu, this is a no-op
  dpkg-reconfigure --frontend noninteractive tzdata

  # software-properties is removed from kali-rolling and debian trixie
  if grep -q "kali-rolling" /etc/os-release || grep -q "trixie" /etc/os-release || grep -qi "parrot" /etc/os-release; then
    apt-get install ${PARROTEXTRA} -y vim wget net-tools locales bzip2 wmctrl mesa-utils bc vulkan-tools
  fi
  if grep -q "kali-rolling" /etc/os-release || grep -q "trixie" /etc/os-release || grep -qi "parrot" /etc/os-release; then
    apt-get install ${PARROTEXTRA} -y vim wget net-tools locales bzip2 wmctrl bc
  else
    apt-get install ${PARROTEXTRA} -y vim wget net-tools locales bzip2 wmctrl software-properties-common bc
  fi

  install_optional_pkg "apt" "mesa-utils" "apt-get install ${PARROTEXTRA} -y mesa-utils"
  install_first_available_pkg "apt" "apt-get install ${PARROTEXTRA} -y" mesa-utils-extra mesa-demos
  install_optional_pkg "apt" "vainfo" "apt-get install ${PARROTEXTRA} -y vainfo"
  install_optional_pkg "apt" "vulkan-tools" "apt-get install ${PARROTEXTRA} -y vulkan-tools"
  install_optional_pkg "apt" "mesa-va-drivers" "apt-get install ${PARROTEXTRA} -y mesa-va-drivers"
  install_optional_pkg "apt" "mesa-vulkan-drivers" "apt-get install ${PARROTEXTRA} -y mesa-vulkan-drivers"
  install_optional_pkg "apt" "xserver-xorg-video-amdgpu" "apt-get install ${PARROTEXTRA} -y xserver-xorg-video-amdgpu"
  install_optional_pkg "apt" "xserver-xorg-video-ati" "apt-get install ${PARROTEXTRA} -y xserver-xorg-video-ati"
  install_optional_pkg "apt" "libdrm-amdgpu1" "apt-get install ${PARROTEXTRA} -y libdrm-amdgpu1"
  install_optional_pkg "apt" "libdrm-radeon1" "apt-get install ${PARROTEXTRA} -y libdrm-radeon1"
  if [ "${INSTALL_INTEL_VA_DRIVERS}" == "true" ]; then
    install_optional_pkg "apt" "intel-media-va-driver" "apt-get install ${PARROTEXTRA} -y intel-media-va-driver"
    install_optional_pkg "apt" "i965-va-driver" "apt-get install ${PARROTEXTRA} -y i965-va-driver"
  fi

  # Install openssh-client on Ubuntu
  if grep -q "ubuntu" /etc/os-release; then
    apt-get install -y openssh-client --no-install-recommends
  fi

  echo "generate locales for en_US.UTF-8"
  locale-gen en_US.UTF-8
fi

if [ "$DISTRO" = "ubuntu" ] && ! grep -qE "24.04|26.04" /etc/os-release; then
  #update mesa to latest
  add-apt-repository ppa:kisak/turtle
  apt-get update
  apt full-upgrade -y
elif [ "$DISTRO" = "ubuntu" ] && grep -qE "24.04|26.04" /etc/os-release; then
  userdel ubuntu
  rm -Rf /home/ubuntu
fi
