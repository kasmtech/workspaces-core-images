#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://gitlab.com/kasm-technologies/playground/el/xfce_touch_fix.git"
BUILD_DIR="/tmp/xfce_touch_fix_build"
INSTALL_DIR="${STARTUPDIR}/xfce_touch_fix"

if [ -n "${GITLAB_TOKEN:-}" ]; then
  REPO_URL="https://gitlab-ci-token:${GITLAB_TOKEN}@gitlab.com/kasm-technologies/playground/el/xfce_touch_fix.git"
fi

echo "Install build dependencies for xfce_touch_fix"
if [[ "${DISTRO}" == @(ubuntu|debian|kali|parrotos7) ]]; then
  apt-get update
  apt-get install -y --no-install-recommends gcc git make
elif [[ "${DISTRO}" == @(fedora42|fedora43) ]]; then
  dnf install -y gcc git make
elif [[ "${DISTRO}" == @(oracle8|oracle9|rhel9|rockylinux8|rockylinux9|almalinux8|almalinux9|centos) ]]; then
  yum install -y gcc git make
elif [[ "${DISTRO}" == "opensuse" ]]; then
  zypper install -yn gcc git make
elif [[ "${DISTRO}" == "alpine" ]]; then
  apk add --no-cache gcc git make musl-dev
fi

echo "Clone and build xfce_touch_fix"
git clone --depth=1 "${REPO_URL}" "${BUILD_DIR}"

mkdir -p "${INSTALL_DIR}"
make -C "${BUILD_DIR}" -j"$(nproc)"
find "${BUILD_DIR}" -maxdepth 2 -type f -executable -not -path "${BUILD_DIR}/.git/*" \
  -exec cp {} "${INSTALL_DIR}/" \;

echo "Cleanup xfce_touch_fix build artifacts"
rm -rf "${BUILD_DIR}"

if [[ "${DISTRO}" == @(ubuntu|debian|kali|parrotos7) ]]; then
  apt-get clean
  rm -rf /var/lib/apt/lists/*
elif [[ "${DISTRO}" == @(fedora42|fedora43) ]]; then
  dnf clean all
elif [[ "${DISTRO}" == @(oracle8|oracle9|rhel9|rockylinux8|rockylinux9|almalinux8|almalinux9|centos) ]]; then
  yum clean all
elif [[ "${DISTRO}" == "opensuse" ]]; then
  zypper clean --all
fi
