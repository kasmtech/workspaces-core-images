#!/usr/bin/env bash
set -ex

apt-get update

apt-get install -y procps  dbus-x11

# Install the standard default kali tools
#   https://tools.kali.org/kali-metapackages
# kali-linux-default use mlocate which breaks plocate
apt-get remove -y plocate
apt-get install -y kali-linux-default

# Kali  installs firefox by default. We need to update this install to utilze the system's certificate store
#   in order for web filtering to work

apt-get install -y p11-kit-modules

rm -rf /usr/lib/firefox-esr/libnssckbi.so
ln /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox-esr/libnssckbi.so


# Kali includes chromium by default.
CHROME_ARGS="--password-store=basic --no-sandbox --disable-gpu --user-data-dir --no-first-run"

mv /usr/bin/chromium /usr/bin/chromium-orig
cat >/usr/bin/chromium <<EOL
#!/usr/bin/env bash
/usr/bin/chromium-orig  ${CHROME_ARGS} "\$@"
EOL
chmod +x /usr/bin/chromium

mkdir -p /etc/chromium/policies/managed
cat >> /etc/chromium/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
EOL

# Vanilla Chrome looks for policies in /etc/opt/chrome/policies/managed which is used by web filtering.
#   Create a symlink here so filter is applied to chromium as well.
mkdir -p /etc/opt/chrome/policies/
ln -s /etc/chromium/policies/managed /etc/opt/chrome/policies/
