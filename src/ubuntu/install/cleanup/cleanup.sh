#!/usr/bin/env bash
set -ex

# Distro package cleanup
if [[ "${DISTRO}" == @(centos|oracle7) ]] ; then
  yum clean all
elif [[ "${DISTRO}" == @(almalinux8|almalinux9|fedora37|fedora38|fedora39|oracle8|oracle9|rockylinux8|rockylinux9) ]]; then
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper clean --all
elif [[ "${DISTRO}" == @(debian|kali|parrotos6|ubuntu) ]]; then
  # Uninstall unneccesary/vulnerable packages
  dpkg --purge ipp-usb #KASM-5266

  apt-get autoremove -y
  apt-get autoclean -y
fi

# File cleanups
rm -Rf \
  /home/kasm-default-profile/.cache \
  /home/kasm-user/.cache \
  /tmp \
  /var/lib/apt/lists/* \
  /var/tmp/*
mkdir -m 1777 /tmp

# Remove xfce4-screensaver bin if it exists
if which xfce4-screensaver; then
  rm -f $(which xfce4-screensaver)
fi

# Services we don't want to start disable in xfce init
rm -f \
  /etc/xdg/autostart/blueman.desktop \
  /etc/xdg/autostart/geoclue-demo-agent.desktop \
  /etc/xdg/autostart/gnome-keyring-pkcs11.desktop \
  /etc/xdg/autostart/gnome-keyring-secrets.desktop \
  /etc/xdg/autostart/gnome-keyring-ssh.desktop \
  /etc/xdg/autostart/gnome-shell-overrides-migration.desktop \
  /etc/xdg/autostart/light-locker.desktop \
  /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.A11ySettings.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Color.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Datetime.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Housekeeping.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Keyboard.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.MediaKeys.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Power.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.PrintNotifications.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Rfkill.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.ScreensaverProxy.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Sharing.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Smartcard.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Sound.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.UsbProtection.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Wacom.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Wwan.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.XSettings.desktop \
  /etc/xdg/autostart/pulseaudio.desktop \
  /etc/xdg/autostart/xfce4-power-manager.desktop \
  /etc/xdg/autostart/xfce4-screensaver.desktop \
  /etc/xdg/autostart/xfce-polkit.desktop \
  /etc/xdg/autostart/xscreensaver.desktop

# Cleanup specific to KasmOS
if [ "$1" = "kasmos" ] ; then
  echo "Removing packages from base"
  packages=("konsole" "geeqie" "gwenview" "imagemagick-6.q16" "kate" "dolphin")
  for package in ${packages[@]}; do
    if [[ $(apt -qq list "$package") ]] ; then
      echo "Removing package $package."
      apt remove -y ${package}
    else
      echo "Package ${package} not found."
    fi
  done
 apt autoremove -y

fi
