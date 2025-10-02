#!/bin/bash
### every exit != 0 fails the script
set -ex

COMMIT_ID="c5a0041bdbae2e42ec27118cef35ce0f75faf2f1"
BRANCH="main"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum install -y wget nss-tools glib2
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|oracle8|oracle9|rhel9|rockylinux8|rockylinux9|fedora37|fedora38|fedora39|fedora40|fedora41) ]]; then
  dnf install -y wget nss-tools glib2
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn wget mozilla-nss-tools libglib-2_0-0
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache wget nss-tools glib
else
  apt-get update
  apt-get install -y wget libnss3-tools libglib2.0-0
fi

# download the prebuilt dependencies
DEPS_VERSION="current"

if [[ "${DISTRO}" == @(oracle8|almalinux8|rockylinux8|opensuse) ]]; then
  DEPS_VERSION="compat"
elif [[ "${DISTRO}" == "ubuntu" ]] && grep -E "(focal|bionic)" /etc/os-release >/dev/null 2>&1; then
  DEPS_VERSION="compat"
elif [[ "${DISTRO}" == "debian" ]] && grep -E "(bullseye|buster|stretch)" /etc/os-release >/dev/null 2>&1; then
  DEPS_VERSION="compat"
fi

mkdir -p /tmp/smartcard
wget -q  https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_smartcard_bridge/${COMMIT_ID}/kasm_smartcard_bridge_deps_${DEPS_VERSION}_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz
tar -xvzf kasm_smartcard_bridge_deps_${DEPS_VERSION}_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz -C /tmp/smartcard/
rm  kasm_smartcard_bridge_deps_${DEPS_VERSION}_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz

# install pcsc-lite
cd /tmp/smartcard/pcsc
mkdir -p "/run/pcscd"
cp -r usr/* /usr/ 2>/dev/null || true
sed -i "s|prefix=.*|prefix=/usr|g" "/usr/lib/pkgconfig/libpcsclite.pc"
sed -i "s|libdir=.*|libdir=/usr/lib|g" "/usr/lib/pkgconfig/libpcsclite.pc"
sed -i "s|includedir=.*|includedir=/usr/include|g" "/usr/lib/pkgconfig/libpcsclite.pc"

# install virtualsmartcard
cd /tmp/smartcard/virtualsmartcard
cp -r usr/lib/* /usr/lib/ 2>/dev/null || true
command -v ldconfig >/dev/null 2>&1 && ldconfig || true

# install opensc
cd /tmp/smartcard/opensc
cp -r usr/* /usr/ 2>/dev/null || true
cp -r etc/* /etc/ 2>/dev/null || true
command -v ldconfig >/dev/null 2>&1 && ldconfig || true

# configure OpenSC module through p11-kit configuration
if [ -f "/usr/lib/opensc-pkcs11.so" ]; then
  OPENSC_LIB="/usr/lib/opensc-pkcs11.so"
elif [ -f "/usr/lib64/opensc-pkcs11.so" ]; then
  OPENSC_LIB="/usr/lib64/opensc-pkcs11.so"
else
  OPENSC_LIB=$(find /usr -name "opensc-pkcs11.so" 2>/dev/null | head -1)
fi

if [ -z "$OPENSC_LIB" ]; then
  echo "ERROR: opensc-pkcs11.so not found"
  exit 1
fi

mkdir -p /etc/pkcs11/modules
cat > /etc/pkcs11/modules/opensc.module <<EOF
module: $OPENSC_LIB
managed: yes
priority: 50
EOF

# override with custom OpenSC configuration
cp $INST_SCRIPTS/smartcard/opensc.conf /etc/opensc/opensc.conf

# register OpenSC module
mkdir -p $HOME/.pki/nssdb
echo "library=${OPENSC_LIB}" >> $HOME/.pki/nssdb/pkcs11.txt
echo "name=OpenSC PKCS#11" >> $HOME/.pki/nssdb/pkcs11.txt

# configure a VPCD device
mkdir -p /etc/reader.conf.d
cp $INST_SCRIPTS/smartcard/vpcd.conf /etc/reader.conf.d/vpcd

# download the smartcard bridge
mkdir -p $STARTUPDIR/smartcard
wget -q  https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_smartcard_bridge/${COMMIT_ID}/kasm_smartcard_bridge_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz
tar -xvzf kasm_smartcard_bridge_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz -C $STARTUPDIR/smartcard/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/smartcard/kasm_smartcard_bridge.version

# register and pin the packages for Kali Linux to prevent
# the installation of the version of the packages that use a different
#client protocol version than the one used by the kasm-smartcard-bridge
if [[ "${DISTRO}" == @(kali) ]]; then
    cat >> /var/lib/dpkg/status <<EOF
Package: pcscd
Status: install ok installed
Priority: optional
Section: utils
Installed-Size: 1024
Maintainer: Kasm Technologies
Architecture: $(dpkg --print-architecture)
Version: 2.0.1-kasm
Description: Custom PCSC daemon

Package: libpcsclite1
Status: install ok installed
Priority: optional
Section: libs
Installed-Size: 512
Maintainer: Kasm Technologies
Architecture: $(dpkg --print-architecture)
Version: 2.0.1-kasm
Description: Custom PCSC library

Package: libpcsclite-dev
Status: install ok installed
Priority: optional
Section: libdevel
Installed-Size: 256
Maintainer: Kasm Technologies
Architecture: $(dpkg --print-architecture)
Version: 2.0.1-kasm
Description: Custom PCSC development files

Package: opensc
Status: install ok installed
Priority: optional
Section: utils
Installed-Size: 2048
Maintainer: Kasm Technologies
Architecture: $(dpkg --print-architecture)
Version: 0.22.0-kasm
Description: Custom OpenSC smartcard utilities
EOF

cat << EOF | tee /etc/apt/preferences.d/smartcard-pin
Package: pcscd
Pin: version 2.0.1-kasm
Pin-Priority: 1001

Package: libpcsclite1
Pin: version 2.0.1-kasm
Pin-Priority: 1001

Package: libpcsclite-dev
Pin: version 2.0.1-kasm
Pin-Priority: 1001

Package: opensc
Pin: version 0.22.0-kasm
Pin-Priority: 1001
EOF

apt-get update
fi

# clean up
rm -rf /tmp/smartcard
rm -rf $STARTUPDIR/smartcard/kasm_smartcard_bridge_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz

# script for waiting on smartcard service to be ready
cat >/usr/bin/smartcard_ready <<EOL
#!/usr/bin/env bash
set -x
if [[ \${KASM_SVC_SMARTCARD:-1} == 1 ]]; then
  echo "Waiting for pcscd to be ready"
  until pgrep -x pcscd > /dev/null; do sleep 1; done
  echo "Smartcard service is ready"
else
  echo "Smartcard service is not enabled"
fi
EOL
chmod +x /usr/bin/smartcard_ready
