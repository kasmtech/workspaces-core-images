#!/usr/bin/env bash
set -ex

if [[ "${DISTRO}" == "ubuntu" ]] ; then
  sed -i \
    '/locale/d' \
    /etc/dpkg/dpkg.cfg.d/excludes
elif [[ "${DISTRO}" == "debian" ]] ; then
  sed -i \
    '/locale/d' \
    /etc/dpkg/dpkg.cfg.d/docker
  if grep -q bullseye /etc/os-release; then
    # Debian 11 (bullseye) has aged out of security.debian.org and archive.debian.org hasn't backfilled it yet,
    # Pin to a snapshot.debian.org timestamp from before the cutover instead.
    SNAPSHOT_TS="20260824T000000Z"
    cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${SNAPSHOT_TS} bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${SNAPSHOT_TS} bullseye-security main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${SNAPSHOT_TS} bullseye-updates main
EOF
  fi
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora42|fedora43|oracle8|oracle9|rhel9|rockylinux8|rockylinux9) ]]; then
  rm -f /etc/rpm/macros.image-language-conf
fi

echo "Upgrading packages from upstream base image"
if [[ "${DISTRO}" == @(fedora42|fedora43|oracle8|oracle9|rhel9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf upgrade -y --refresh
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper --non-interactive patch --auto-agree-with-licenses
elif [ "${DISTRO}" == "alpine" ]; then
  apk update
  apk add --upgrade apk-tools
  apk upgrade --available
elif [[ "${DISTRO}" == "parrotos7" ]]; then
  sed -i 's|https://deb.parrot.sh/parrot|https://mirrors.mit.edu/parrot|g' /etc/apt/sources.list.d/parrot.list
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
else
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
fi
