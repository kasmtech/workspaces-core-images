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
    ## Debian 11 (bullseye) has aged out of security.debian.org and archive.debian.org hasn't backfilled it yet,
    # Pin to a snapshot.debian.org timestamp from before the cutover instead.
    # Apt's integrity model doesn't depend on transport encryption. 
    # The Release/InRelease file is GPG-signed using keys already baked into the base image
    SNAPSHOT_TS="20260901T090127Z"
    cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${SNAPSHOT_TS} bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${SNAPSHOT_TS} bullseye-security main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${SNAPSHOT_TS} bullseye-updates main
EOF
    # snapshot.debian.org is a rate-limited archive and intermittently
    # answers with 503/504/connection-reset. Setting retries to help some.
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99snapshot-retries
  fi
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora37|fedora38|fedora39|fedora40|fedora41|oracle8|oracle9|rhel9|rockylinux8|rockylinux9) ]]; then
  rm -f /etc/rpm/macros.image-language-conf
elif [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  sed -i \
    '/override_install_langs/d' \
    /etc/yum.conf
  yum reinstall -y \
    glibc-common
fi

echo "Upgrading packages from upstream base image"
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum update -y
elif [[ "${DISTRO}" == @(fedora37|fedora38|fedora39|fedora40|fedora41|oracle8|oracle9|rhel9|rockylinux9|rockylinux8|almalinux8|almalinux9) ]]; then
  dnf upgrade -y --refresh
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper --non-interactive patch --auto-agree-with-licenses
elif [ "${DISTRO}" == "alpine" ]; then
  apk update
  apk add --upgrade apk-tools
  apk upgrade --available
else
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
fi
