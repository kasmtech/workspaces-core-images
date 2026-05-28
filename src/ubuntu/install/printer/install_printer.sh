#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo $DISTRO

if [[ "${DISTRO}" == @(almalinux8|almalinux9|oracle8|oracle9|rhel9|rockylinux8|rockylinux9|fedora42|fedora43) ]]; then
  dnf install -y cups cups-client cups-pdf
elif [ "${DISTRO}" == "opensuse" ]; then
  if grep -q "16" /etc/os-release; then
      zypper addrepo -G https://download.opensuse.org/repositories/Printing/16.0/ printing
  fi
  zypper install --allow-vendor-change -y cups cups-client
  if [[ "$(uname -m)" == "aarch64" ]]; then
    curl -O https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_backend/opensuse-cups-pdf-arm/3.0.2/cups-pdf-3.0.2-lp160.15.3.aarch64.rpm
    zypper --no-gpg-checks install -y ./cups-pdf-3.0.2-lp160.15.3.aarch64.rpm
    rm -f ./cups-pdf-3.0.2-lp160.15.3.aarch64.rpm
  else
    zypper install --allow-vendor-change -y cups-pdf
  fi
elif [ "${DISTRO}" == "alpine" ]; then
  echo '@edge-community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
  apk add --no-cache cups cups-client cups-pdf@edge-community
  usermod -a -G lpadmin root
else
  apt-get update
  apt-get install -y cups-filters 
  apt-get install -y cups cups-client printer-driver-cups-pdf
fi

# change the default path where pdfs are saved
# to the one watched by the printer service
sed -i -r -e "s:^(Out\s).*:\1/home/kasm-user/PDF:" /etc/cups/cups-pdf.conf

COMMIT_ID="8a006be9c56e179daa80293fde4f37cfa8d600cb"
BRANCH="develop"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/printer
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_printer_service/${COMMIT_ID}/kasm_printer_service_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/printer/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/printer/kasm_printer.version


cat >/usr/bin/printer_ready <<EOL
#!/usr/bin/env bash
set -x
if [[ \${KASM_SVC_PRINTER:-1} == 1 ]]; then
  PRINTER_NAME=\${KASM_PRINTER_NAME:-Kasm-Printer}
  until [[ "\$(lpstat -r)" == "scheduler is running" ]]; do sleep 1; done
  echo "Scheduler is running"

  until lpstat -p "\$PRINTER_NAME" | grep -q "is idle"; do
      sleep 1
  done
  echo "Printer \$PRINTER_NAME is idle."
else
  echo "Printing service is not enabled"
fi
EOL
chmod +x /usr/bin/printer_ready
