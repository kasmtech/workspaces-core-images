download_rpm() {
  if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] ; then
    url=https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/VirtualGL-3.1.3.aarch64.rpm
  else
    url=https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/VirtualGL-3.1.3.x86_64.rpm
  fi

  wget -O "$virtualgl_rpm" "$url"
}

cleanup_rpm() {
  rm "$virtualgl_rpm"
}

skip_parrotos_due_to_i386_dependencies_lacking() {
  if [[ "$DISTRO" == @(parrotos6|parrotos7) ]]; then
    exit
  fi
}

set -e

virtualgl_deb=/tmp/virtualgl.deb
virtualgl_rpm=/tmp/virtualgl.rpm

BUILD_ARCH=$(arch)

skip_parrotos_due_to_i386_dependencies_lacking

if command -v apt-get &>/dev/null; then
  if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] ; then
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxdmcp6 libxcb1 libxext6 libx11-6
    apt-get update && apt-get install -y --no-install-recommends \
        libglvnd0 libgl1 libglx0 libegl1 libgles2

    wget -O "$virtualgl_deb" https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/virtualgl_3.1.3_arm64.deb
  else
    dpkg --add-architecture i386
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386
    apt-get update
    if ! apt-get install -y --no-install-recommends \
        libglvnd0 libglvnd0:i386 \
        libgl1 libgl1:i386 \
        libglx0 libglx0:i386 \
        libegl1 libegl1:i386 \
        libgles2 libgles2:i386; then
      echo "WARNING: 32-bit (i386) GL libraries are not currently installable; \
continuing with amd64-only GL (no 32-bit OpenGL support under VirtualGL)." >&2
      apt-get install -y --no-install-recommends \
          libglvnd0 libgl1 libglx0 libegl1 libgles2
    fi

    if [[ "$DISTRO" = "ubuntu" ]] && ! grep -q "24.04" /etc/os-release; then
      add-apt-repository ppa:kisak/turtle
      apt full-upgrade -y
    fi
    wget -O "$virtualgl_deb"  https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/virtualgl_3.1.3_amd64.deb
  fi

  apt-get install -y "$virtualgl_deb"
  rm "$virtualgl_deb"
fi

if [[ "$DISTRO" =~ ^opensuse ]]; then
  download_rpm
  zypper --no-gpg-checks install -y "$virtualgl_rpm"
  cleanup_rpm
elif command -v dnf &>/dev/null; then
  download_rpm
  dnf install -y "$virtualgl_rpm"
  cleanup_rpm
fi

rm -rf $INST_SCRIPTS/virtualgl/
