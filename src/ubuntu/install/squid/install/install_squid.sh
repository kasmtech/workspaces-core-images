#!/bin/bash
set -ex

# Install openssl
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [[ "${DISTRO}" == @(oracle8|oracle9|rhel9|fedora42|fedora43|almalinux8|almalinux9|rockylinux8|rockylinux9) ]]; then
  dnf install -y openssl xkbcomp
  rm -f /etc/X11/xinit/xinitrc
elif [[ "${DISTRO}" == "alpine" ]]; then
  apk add --no-cache openssl
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn openssl
else
  apt-get update
  apt-get install -y openssl
fi

# Intall squid
SQUID_COMMIT='eeb77407cf8ae952078520d8f4f231958a0ad98f'
if grep -q Focal /etc/os-release || grep -q bullseye /etc/os-release || [[ "${DISTRO}" == @(oracle8|almalinux8|rockylinux8) ]]; then
  if wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_ubuntu11_${ARCH}.tar.gz | tar -xzf - -C / 2>/dev/null; then
    echo "Squid builder ubuntu11 installed"
  else
    echo "Warning: Squid builder ubuntu11 binary not available"
  fi
elif [[ "${DISTRO}" == "alpine" ]]; then
  if wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_alpine_${ARCH}.tar.gz | tar -xzf - -C / 2>/dev/null; then
    echo "Squid builder alpine installed"
  else
    echo "Warning: Squid builder alpine binary not available"
  fi
else
  if wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_ubuntu_${ARCH}.tar.gz | tar -xzf - -C / 2>/dev/null; then
    echo "Squid builder ubuntu installed"
  else
    echo "Warning: Squid builder binary not available for $DISTRO"
  fi
fi

# Update squid conf with user info
if [[ "${DISTRO}" == @(oracle8|oracle9|rhel9|fedora42|fedora43|almalinux8|almalinux9|rockylinux8|rockylinux9|alpine) ]]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
elif [ "${DISTRO}" == "opensuse" ]; then
  if ! getent group proxy >/dev/null; then
    groupadd -g