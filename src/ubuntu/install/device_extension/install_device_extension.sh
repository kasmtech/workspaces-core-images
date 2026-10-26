#!/bin/bash
### every exit != 0 fails the script
set -ex

if [ ! -d "$STARTUPDIR/smartcard/workspace-device-extension" ]; then
  echo "ERROR: $STARTUPDIR/smartcard/workspace-device-extension not found - did install_smartcard.sh run first?" >&2
  exit 1
fi

mkdir -p $STARTUPDIR/device_extension
mv $STARTUPDIR/smartcard/workspace-device-extension $STARTUPDIR/device_extension/workspace-device-extension

if [ -f "$STARTUPDIR/smartcard/workspace-device-extension.crx" ]; then
  mv "$STARTUPDIR/smartcard/workspace-device-extension.crx" \
     "$STARTUPDIR/device_extension/workspace-device-extension.crx"
  chmod 644 "$STARTUPDIR/device_extension/workspace-device-extension.crx"
  echo "Staged signed workspace-device-extension.crx"
else
  # Not fatal: bridge builds from a ref without access to the signing key omit the
  # CRX, which still leaves a usable image for every browser except Google Chrome.
  echo "WARNING: no workspace-device-extension.crx in the bridge tarball; Google Chrome will not load the device extension" >&2
fi
