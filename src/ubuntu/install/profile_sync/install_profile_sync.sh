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
    opensuse) 
      if grep -q '16' /etc/os-release; then
        profile_distro="opensuse_16"
      fi
      ;;
    alpine)
      if grep -q 'v3.21' /etc/os-release; then
        profile_distro="alpine_321"
      fi
      if grep -q 'v3.22' /etc/os-release; then
        profile_distro="alpine_322"
      fi
      if grep -q 'v3.23' /etc/os-release; then
        profile_distro="alpine_323"
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
  if [[ "$DISTRO" = @(debian|ubuntu|kali|parrot*) ]]; then
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
BRANCH="release_1.1.1"
COMMIT_ID="bdda739846603351abce617cd3c3ebaacdd44ff8"
download_and_symlink

# profile-sync-v2
BRANCH="release_2.1.0"
COMMIT_ID="c10d82f8492d711c01b67a97cb20bec0c357cf06"
install_v2_dependencies
download_and_symlink_v2