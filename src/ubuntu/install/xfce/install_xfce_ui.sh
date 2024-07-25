#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

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
if [[ "${DISTRO}" != @(centos|oracle7|oracle8|opensuse|fedora37|fedora38|fedora39|fedora40|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
  apt-get update
fi

if [ "${DISTRO}" == "kali" ]; then
  apt-get install --no-install-recommends -y \
    atril \
    dbus-x11 \
    libnotify-bin \
    engrampa \
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
    xfce4-whiskermenu-plugin \
    xfce4-notifyd
elif [[ "$DISTRO" = @(ubuntu|debian) ]]; then
  apt-get install -y \
    dbus-x11 \
    supervisor \
    xfce4 \
    xfce4-terminal \
    xterm \
    xclip
elif [[ "$DISTRO" = "parrotos6" ]]; then
  apt-get install -y \
    dbus-x11 \
    desktop-base \
    maia-icon-theme \
    parrot-menu \
    parrot-themes \
    parrot-wallpapers \
    supervisor \
    xclip \
    xfce4 \
    xfce4-terminal \
    xfce4-whiskermenu-plugin
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
  yum install -y \
    gvfs \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset
elif [ "$DISTRO" = "oracle8" ]; then
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf group install xfce -y
  dnf install -y \
    gvfs \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset
elif [ "$DISTRO" = "oracle9" ]; then
  dnf config-manager --set-enabled ol9_codeready_builder
  dnf config-manager --set-enabled ol9_distro_builder
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf group install xfce -y -x oracle-backgrounds
  dnf install -y \
    dbus-x11 \
    gvfs \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset
elif [[ "$DISTRO" == @(rockylinux9|almalinux9) ]]; then
  dnf config-manager --set-enabled crb
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf group install xfce -y
  dnf install -y \
    gvfs \
    dbus-x11 \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset

    # fix for xfce4-notifyd not being rachable
    dbus-uuidgen --ensure
    cat > /usr/share/dbus-1/services/org.freedesktop.Notifications.service <<EOL
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib64/xfce4/notifyd/xfce4-notifyd
EOL
elif [[ "$DISTRO" == @(rockylinux8|almalinux8) ]]; then
  dnf config-manager --set-enabled powertools
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf group install xfce -y
  dnf install -y \
    gvfs \
    dbus-x11 \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset

    # fix for xfce4-notifyd not being rachable
    dbus-uuidgen --ensure
  cat > /usr/share/dbus-1/services/org.freedesktop.Notifications.service <<EOL
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib64/xfce4/notifyd/xfce4-notifyd
EOL
elif [ "$DISTRO" = "opensuse" ]; then
  zypper install -yn -t pattern xfce
  zypper install -yn \
    gvfs \
    xclip \
    xfce4-terminal \
    xfce4-notifyd \
	  kdialog \
    xset
  # Pidof is no longer shipped in OpenSuse
  ln -s /usr/bin/pgrep /usr/bin/pidof
elif [[ "$DISTRO" = @(fedora37|fedora38|fedora39|fedora40) ]]; then
  dnf group install xfce -y
  dnf install -y \
    gvfs \
    wmctrl \
    xclip \
    xfce4-notifyd \
    xset

  # fix for xfce4-notifyd not being rachable
  dbus-uuidgen --ensure
  cat > /usr/share/dbus-1/services/org.freedesktop.Notifications.service <<EOL
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib64/xfce4/notifyd/xfce4-notifyd
EOL
elif [ "$DISTRO" = "alpine" ]; then
  apk add --no-cache \
    dbus-x11 \
    faenza-icon-theme \
    faenza-icon-theme-xfce4-appfinder \
    faenza-icon-theme-xfce4-panel \
    gvfs \
    mesa \
    mesa-dri-gallium \
    mesa-gl \
    mousepad \
    thunar \
    xfce4 \
    xfce4-terminal \
    xfce4-notifyd
  rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop

  # fix for xfce4-notifyd not being rachable
  dbus-uuidgen --ensure
  cat > /usr/share/dbus-1/services/org.freedesktop.Notifications.service <<EOL
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/xfce4/notifyd/xfce4-notifyd
EOL
fi

if [[ "${DISTRO}" != @(centos|oracle7|oracle8|fedora37|fedora38|fedora39|fedora40|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
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
if [ -z \${START_DE+x} ]; then \
  START_DE="xfce4-session"
fi
until pids=\$(pidof \${START_DE}); do sleep .5; done
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

# Support desktop icon trust
cat >>/etc/xdg/autostart/desktop-icons.desktop<<EOL
[Desktop Entry]
Type=Application
Name=Desktop Icon Trust
Exec=/dockerstartup/trustdesktop.sh
EOL
chmod +x /etc/xdg/autostart/desktop-icons.desktop
