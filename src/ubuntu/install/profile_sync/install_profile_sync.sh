#!/usr/bin/env bash

set -eo pipefail

check_distro_is_supported() {
  if [[ "$profile_distro" = oracle_7 ]]; then
    exit
  fi
}

delimit_distro_version_with_underscore() {
  local distro="$1"
  echo "$distro" | sed 's/^\([a-zA-Z]\+\)\([0-9]\+\)$/\1_\2/'
}

detect_deb_distro() {
  local distro
  local codename
  local full_name

  distro=$(grep -Po -m 1 '(?<=PRETTY_NAME=")[^ ]+' /etc/os-release)
  codename=$(grep -Po -m 1 "(?<=_CODENAME=)\w+" /etc/os-release)
  full_name="${distro}_${codename}"
  echo "${full_name,,}"
}

handle_debian_and_ubuntu_conversion() {
  if [[ "$DISTRO" = @(debian|ubuntu) ]]; then
    profile_distro=$(detect_deb_distro)
  fi
}

handle_other_distros_conversion() {
  profile_distro=$(delimit_distro_version_with_underscore "$DISTRO")

  case "$DISTRO" in
    kali) profile_distro="kali_kali-rolling"
      ;;
    opensuse) profile_distro="opensuse_15"
      ;;
    alpine)
      if grep -q 'v3.17' /etc/os-release; then
        profile_distro="alpine_317"
      fi
      if grep -q 'v3.18' /etc/os-release; then
        profile_distro="alpine_318"
      fi
      if grep -q 'v3.19' /etc/os-release; then
        profile_distro="alpine_319"
      fi
      if grep -q 'v3.20' /etc/os-release; then
        profile_distro="alpine_320"
      fi
      if grep -q 'v3.21' /etc/os-release; then
        profile_distro="alpine_321"
      fi
      ;;
    rockylinux*)
      profile_distro=$(echo "$profile_distro" | sed -e 's/linux//')
      ;;
    almalinux*)
      profile_distro=$(echo "$profile_distro" | sed -e 's/linux//')
      ;;
    rhel*)
      profile_distro=$(echo "$profile_distro" | sed -e 's/rhel/oracle/')
      ;;
  esac
}

convert_local_distro_to_profile_sync_distro() {
  handle_debian_and_ubuntu_conversion
  if [ -n "$profile_distro" ]; then
    return
  fi

  handle_other_distros_conversion
}

download_and_symlink() {
  COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)
  BINARY_NAME="${profile_distro}_${BRANCH}_${COMMIT_ID_SHORT}_${ARCH}-kasm-profile-sync"
  BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/profile-sync/${COMMIT_ID}/${BINARY_NAME}"

  cd /usr/bin/
  wget "$BUILD_URL"
  chmod +x "$BINARY_NAME"
  ln -s "$BINARY_NAME" kasm-profile-sync
}

download_and_symlink_v2() {
  COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)
  BINARY_NAME="${profile_distro}_${BRANCH}_${COMMIT_ID_SHORT}_${ARCH}-kasm-profile-sync-2"
  BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/profile-sync/${COMMIT_ID}/${BINARY_NAME}"

  cd /usr/bin/
  wget "$BUILD_URL"
  chmod +x "$BINARY_NAME"
  ln -s "$BINARY_NAME" kasm-profile-sync-2
}

install_v2_dependencies() {
  # Install libarchive 13 on distros that need it
  if [[ "$DISTRO" = @(debian|ubuntu|kali) ]]; then
    apt-get update
    apt-get install -y libarchive13
  elif [[ "$DISTRO" = @(opensuse) ]]; then
     zypper install -yn libarchive13
  elif [ "${DISTRO}" == "alpine" ]; then
      apk add --no-cache  libarchive
  elif [[ "${DISTRO}" == @(fedora*|oracle*|rockylinux*|almalinux*|rhel*) ]]; then
      dnf install -y libarchive
  fi
}

ARCH=$(arch)
convert_local_distro_to_profile_sync_distro
check_distro_is_supported

# profile-sync-v1
BRANCH="release_1.1.0"
COMMIT_ID="9c2c59f08fab0824feef460454ef079c5f2dd21d"
download_and_symlink

# profile-sync-v2
BRANCH="release_2.0.0"
COMMIT_ID="299a7ead1350e4ddd8e3b59a1186a8dc11673a05"
install_v2_dependencies
download_and_symlink_v2