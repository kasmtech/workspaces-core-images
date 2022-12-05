BUILD_ARCH=$(uname -p)

if [ "$DISTRO" = "ubuntu" ]; then
  #install virtualgl
  #wget https://sourceforge.net/projects/virtualgl/files/2.6.95%20%283.0rc1%29/virtualgl_2.6.95_amd64.deb -P /tmp

  if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] ; then
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxdmcp6 libxcb1 libxext6 libx11-6
    apt-get update && apt-get install -y --no-install-recommends \
        libglvnd0 libgl1 libglx0 libegl1 libgles2

    dpkg -i $INST_SCRIPTS/virtualgl/virtualgl_*arm64.deb
  else
    dpkg --add-architecture i386
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386
    apt-get update && apt-get install -y --no-install-recommends \
        libglvnd0 libglvnd0:i386 \
        libgl1 libgl1:i386 \
        libglx0 libglx0:i386 \
        libegl1 libegl1:i386 \
        libgles2 libgles2:i386

    add-apt-repository ppa:kisak/turtle
    apt full-upgrade -y
    dpkg -i $INST_SCRIPTS/virtualgl/virtualgl_*amd64.deb
  fi

  apt install -f -y
  rm -rf $INST_SCRIPTS/virtualgl/
fi
