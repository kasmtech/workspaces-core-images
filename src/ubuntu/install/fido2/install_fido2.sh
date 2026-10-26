#!/bin/bash
### every exit != 0 fails the script
set -ex

if [ ! -f "$STARTUPDIR/smartcard/kasm_fido2_bridge" ]; then
  echo "ERROR: $STARTUPDIR/smartcard/kasm_fido2_bridge not found - did install_smartcard.sh run first?" >&2
  exit 1
fi

if [ ! -f "$STARTUPDIR/smartcard/native-messaging-hosts/com.kasm.fido2.json" ]; then
  echo "ERROR: $STARTUPDIR/smartcard/native-messaging-hosts/com.kasm.fido2.json not found - did install_smartcard.sh run first?" >&2
  exit 1
fi

mkdir -p $STARTUPDIR/fido2
mv $STARTUPDIR/smartcard/kasm_fido2_bridge $STARTUPDIR/fido2/kasm_fido2_bridge
cp $STARTUPDIR/smartcard/kasm_smartcard_bridge.version $STARTUPDIR/fido2/kasm_fido2_bridge.version
mv $STARTUPDIR/smartcard/native-messaging-hosts/com.kasm.fido2.json $STARTUPDIR/fido2/com.kasm.fido2.json

# Register the native-messaging host manifest at every Chromium-derived
# browser's systemwide location
NATIVE_MESSAGING_HOST_DIRS=(
  /etc/opt/chrome/native-messaging-hosts
  /etc/chromium/native-messaging-hosts
  /etc/opt/chromium/native-messaging-hosts
  /etc/brave/native-messaging-hosts
  /etc/opt/microsoft/msedge/native-messaging-hosts
  /etc/opt/vivaldi/native-messaging-hosts
  /etc/opt/opera/native-messaging-hosts
)

FIDO2_BRIDGE_PATH=$STARTUPDIR/fido2/kasm_fido2_bridge
for dir in "${NATIVE_MESSAGING_HOST_DIRS[@]}"; do
  mkdir -p "$dir"
  cp $STARTUPDIR/fido2/com.kasm.fido2.json "$dir/com.kasm.fido2.json"
  sed -i "s|__FIDO2_BRIDGE_PATH__|$FIDO2_BRIDGE_PATH|g" "$dir/com.kasm.fido2.json"

  if ! grep -q "\"path\"[[:space:]]*:[[:space:]]*\"$FIDO2_BRIDGE_PATH\"" "$dir/com.kasm.fido2.json"; then
    echo "ERROR: $dir/com.kasm.fido2.json does not point at $FIDO2_BRIDGE_PATH - is the bridge tarball's com.kasm.fido2.json missing the __FIDO2_BRIDGE_PATH__ placeholder?" >&2
    exit 1
  fi
done
