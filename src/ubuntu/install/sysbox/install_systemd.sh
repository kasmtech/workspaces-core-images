#!/usr/bin/env bash
set -ex

# Setup systemd based on distro type
if [[ "${DISTRO}" == @(ubuntu|debian|parrotos6|kali) ]] ; then
  # Install deps
  apt-get update
  apt-get install -y --no-install-recommends \
    dbus \
    iproute2 \
    iptables \
    kmod \
    libsystemd0 \
    sudo \
    systemd \
    systemd-sysv \
    udev
elif [[ "${DISTRO}" == @(oracle8|oracle9|rockylinux9|rockylinux8|almalinux9|almalinux8|fedora37|fedora38|fedora39|fedora40) ]]; then
  # Install deps
  dnf install -y \
    dbus \
    iproute \
    iptables \
    kmod \
    sudo \
    systemd \
    udev
elif [ "${DISTRO}" == "opensuse" ]; then
  # Install deps
  zypper install -y \
    dbus-1 \
    iproute2 \
    iptables \
    kmod \
    sudo \
    systemd \
    systemd-sysvinit \
    udev
fi


# Disable systemd stuff that does not work
echo "ReadKMsg=no" >> /etc/systemd/journald.conf
systemctl mask \
  systemd-udevd.service \
  systemd-journald-audit.socket \
  systemd-udevd-kernel.socket \
  systemd-udevd-control.socket \
  systemd-modules-load.service \
  systemd-udev-trigger.service \
  sys-kernel-config.mount \
  sys-kernel-debug.mount \
  sys-kernel-tracing.mount
rm -f /usr/share/dbus-1/system-services/org.freedesktop.UPower.service

# Generate our standard init systemd service and init helper
cat >/etc/systemd/system/kasm.service<<EOL
[Unit]
Description=Kasm Workspaces Init
After=kasm-setup.service

[Service]
User=kasm-user
Group=kasm-user
EnvironmentFile=/envdump
Type=simple
ExecStart=/bin/bash /dockerstartup/kasm_default_profile.sh /dockerstartup/vnc_startup.sh /dockerstartup/kasm_startup.sh

[Install]
WantedBy=multi-user.target
EOL
cat >/etc/systemd/system/kasm-setup.service<<EOL
[Unit]
Description=Kasm Workspaces root level setup
Before=kasm.service

[Service]
Type=oneshot
ExecStart=/bin/bash /kasm-sysbox-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
cat >/kasm-sysbox-setup.sh<<EOL
#!/bin/bash
mkdir -p /var/run/pulse
chown kasm-user:kasm-user /var/run/pulse
cat /proc/1/environ | xargs --null --max-args=1 > /envdump
if [ -f /usr/sbin/policy-rc.d ]; then
  printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d
fi
systemctl disable gdm
systemctl disable power-profiles-daemon
systemctl disable sshd
systemctl disable unattended-upgrades
systemctl disable upower
systemctl disable wpa_supplicant
systemctl stop gdm
systemctl stop power-profiles-daemon
systemctl stop sshd
systemctl stop unattended-upgrades
systemctl stop upower
systemctl stop wpa_supplicant
EOL
chmod +x /kasm-sysbox-setup.sh
chmod 644 /etc/systemd/system/kasm.service /etc/systemd/system/kasm-setup.service
systemctl enable kasm kasm-setup
