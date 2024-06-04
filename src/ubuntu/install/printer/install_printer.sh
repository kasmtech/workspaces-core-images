#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo $DISTRO

if [ "${DISTRO}" == "oracle7" ] || [ "${DISTRO}" == "centos" ]; then
  yum install -y cups cups-client cups-pdf
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|oracle8|oracle9|rockylinux8|rockylinux9|fedora37|fedora38|fedora39|fedora40) ]]; then
  dnf install -y cups cups-client cups-pdf
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -y cups cups-client cups-pdf
elif [ "${DISTRO}" == "alpine" ]; then
  echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
  apk add --no-cache cups cups-client cups-pdf@testing
  usermod -a -G lpadmin root
else
  apt-get update
  apt-get install -y cups cups-client cups-pdf
fi

# change the default path where pdfs are saved
# to the one watched by the printer service
sed -i -r -e "s:^(Out\s).*:\1/home/kasm-user/PDF:" /etc/cups/cups-pdf.conf

COMMIT_ID="30ca302fa364051fd4c68982da7c5474a7bda6b8"
BRANCH="develop"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/printer
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_printer_service/${COMMIT_ID}/kasm_printer_service_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/printer/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/printer/kasm_printer.version
