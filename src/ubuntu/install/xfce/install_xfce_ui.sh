#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

get_rid_of_policykit_error() {
  rm -f /etc/xdg/autostart/xfce-polkit.desktop
}

disable_epel_nss_wrapper_that_breaks_firefox() {
  yum-config-manager --setopt=epel.exclude=nss_wrapper --save
}

replace_default_xinit() {

  mkdir -p /etc/X11/xinit
  cat >/etc/X11/xinit/xinitrc <<EOL
#!/bin/sh
for file in /etc/X11/xinit/xinitrc.d/* ; do
        . \$file
done
. /etc/X11/Xsession
EOL

chmod +x /etc/X11/xinit/xinitrc
}

replace_default_99x11_common_start() {
  if [ -f /etc/X11/Xsession.d/99x11-common_start ] ; then
    cat >/etc/X11/Xsession.d/99x11-common_start <<EOL
# This file is sourced by Xsession(5), not executed.
# exec $STARTUP
EOL
  fi
}

echo "Install Xfce4 UI components"
if [[ "${DISTRO}" != @(centos|oracle7|oracle8|opensuse|fedora37|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
  apt-get update
fi

if [ "${DISTRO}" == "kali" ]; then
  apt-get install --no-install-recommends -y \
    atril \
    dbus-x11 \
    engrampa \
    kali-debtags \
    kali-defaults-desktop \
    kali-menu \
    kali-themes \
    lightdm \
    mate-calc \
    mousepad \
    parole \
    pavucontrol \
    policykit-1-gnome \
    pulseaudio \
    pulseaudio-utils \
    qt5ct \
    qterminal \
    ristretto \
    thunar-archive-plugin \
    xcape \
    xclip \
    xdg-user-dirs-gtk \
    xfce4 \
    xfce4-cpugraph-plugin \
    xfce4-genmon-plugin \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin
elif [[ "$DISTRO" = @(ubuntu|debian) ]]; then
  apt-get install -y 	dbus-x11 supervisor xfce4 xfce4-terminal xterm xclip
elif [[ "$DISTRO" = "parrotos5" ]]; then
  apt-get install -y maia-icon-theme parrot-themes parrot-wallpapers desktop-base xclip dbus-x11 supervisor xfce4 xfce4-terminal parrot-menu
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
elif [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  if [ "${DISTRO}" == centos ]; then
    yum install -y epel-release
  else
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  
  fi
  disable_epel_nss_wrapper_that_breaks_firefox
  yum groupinstall xfce -y
  yum install -y wmctrl xset xclip xfce4-notifyd
  get_rid_of_policykit_error
  yum remove -y xfce4-power-manager
elif [ "$DISTRO" = "oracle8" ]; then
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf group install xfce -y
  dnf install -y wmctrl xset xclip xfce4-notifyd
  get_rid_of_policykit_error
  dnf remove -y xfce4-power-manager xfce4-screensaver
elif [ "$DISTRO" = "oracle9" ]; then
  dnf config-manager --set-enabled ol9_codeready_builder
  dnf config-manager --set-enabled ol9_distro_builder
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf group install xfce -y -x oracle-backgrounds
  dnf install -y wmctrl xset xclip xfce4-notifyd dbus-x11
  get_rid_of_policykit_error
  dnf remove -y xfce4-power-manager xfce4-screensaver
elif [[ "$DISTRO" == @(rockylinux9|almalinux9) ]]; then
  dnf config-manager --set-enabled crb
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf group install xfce -y
  dnf install -y wmctrl xset xclip xfce4-notifyd dbus-x11
  dnf remove -y xfce4-power-manager xfce4-screensaver
  echo "exit 0" > /usr/libexec/xfce-polkit
elif [[ "$DISTRO" == @(rockylinux8|almalinux8) ]]; then
  dnf config-manager --set-enabled powertools
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf group install xfce -y
  dnf install -y wmctrl xset xclip xfce4-notifyd dbus-x11
  dnf remove -y xfce4-power-manager xfce4-screensaver
  echo "exit 0" > /usr/libexec/xfce-polkit
elif [ "$DISTRO" = "opensuse" ]; then
  zypper install -yn -t pattern xfce
  zypper install -yn xset xfce4-terminal xclip xfce4-notifyd
  zypper remove -yn xfce4-power-manager
  get_rid_of_policykit_error
elif [ "$DISTRO" = "fedora37" ]; then
  dnf group install xfce -y
  dnf install -y wmctrl xset xclip xfce4-notifyd
  get_rid_of_policykit_error
  dnf remove -y xfce4-power-manager xfce4-screensaver
elif [ "$DISTRO" = "alpine" ]; then
  apk add --no-cache \
    dbus-x11 \
    faenza-icon-theme \
    faenza-icon-theme-xfce4-appfinder \
    faenza-icon-theme-xfce4-panel \
    mesa \
    mesa-dri-gallium \
    mesa-gl \
    mousepad \
    thunar \
    xfce4 \
    xfce4-terminal
  rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop
fi

if grep -q Jammy /etc/os-release; then
  apt-get purge -y xfce4-screensaver
fi

if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum clean all
elif [[ "${DISTRO}" == @(fedora37|oracle8|oracle9|rockylinux9|rockylinux8|almalinux9|almalinux8) ]]; then
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper clean --all
elif [ "${DISTRO}" == "alpine" ]; then
  rm -Rf /tmp/*
else
  apt-get purge -y pm-utils xscreensaver*
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

if [[ "${DISTRO}" == @(centos|oracle7|oracle8|fedora37|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
  echo ""
else
  replace_default_xinit
  if [ "${START_XFCE4}" == "1" ] ; then
    replace_default_99x11_common_start
  fi
fi

# Override default login script so users cant log themselves out of the desktop dession
cat >/usr/bin/xfce4-session-logout <<EOL
#!/usr/bin/env bash
notify-send "Logout" "Please logout or destroy this desktop using the Kasm Control Panel" -i /usr/share/icons/ubuntu-mono-dark/actions/22/system-shutdown-panel-restart.svg
EOL

# Add a script for launching Thunar with libnss wrapper.
# This is called by ~.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
cat >/usr/bin/execThunar.sh <<EOL
#!/bin/sh
. $STARTUPDIR/generate_container_user
/usr/bin/Thunar --daemon
EOL
chmod +x /usr/bin/execThunar.sh

cat >/usr/bin/desktop_ready <<EOL
#!/usr/bin/env bash
until pids=\$(pidof xfce4-session); do sleep .5; done
EOL
chmod +x /usr/bin/desktop_ready

# Change the default behavior of the delete key which is to move to trash. This will now prompt the user to permanently
# delete the file instead of moving it to trash
mkdir -p /etc/xdg/Thunar/
cat >>/etc/xdg/Thunar/accels.scm<<EOL
(gtk_accel_path "<Actions>/ThunarStandardView/delete" "Delete")
(gtk_accel_path "<Actions>/ThunarLauncher/delete" "Delete")
(gtk_accel_path "<Actions>/ThunarLauncher/trash-delete-2" "")
(gtk_accel_path "<Actions>/ThunarLauncher/trash-delete" "")
EOL
