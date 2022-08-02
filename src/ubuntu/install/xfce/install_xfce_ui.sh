#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

get_rid_of_policykit_error() {
  rm -f /etc/xdg/autostart/xfce-polkit.desktop
}

disable_epel_nss_wrapper_that_breaks_firefox() {
  yum-config-manager --setopt=epel.exclude=nss_wrapper --save
}

config_xinit_disable_screensaver() {
  mkdir -p /etc/X11/xinit/xinitrc.d/
  cat >/etc/X11/xinit/xinitrc.d/disable_screensaver.sh <<EOL
#!/bin/sh
set -x
xset -dpms
xset s off
xset q
EOL

chmod +x /etc/X11/xinit/xinitrc.d/disable_screensaver.sh
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
if [[ "${DISTRO}" != @(centos|oracle7|oracle8|opensuse) ]]; then
  apt-get update
fi

if [ "${DISTRO}" == "kali" ]  ;
then
    apt-get install -y supervisor kali-desktop-xfce xclip
    # Disable the power management plugin Xfce4 from starting and displaying an error
    PLUGIN_ID=$(grep  power-manager-plugin /etc/xdg/xfce4/panel/default.xml | perl -n -e '/plugin-(\d+)/ && print $1')
    sed -i "s@<value type=\"int\" value=\"${PLUGIN_ID}\"/>@@g" /etc/xdg/xfce4/panel/default.xml
  elif [ "$DISTRO" = "ubuntu" ]; then
    apt-get install -y supervisor xfce4 xfce4-terminal xterm xclip
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
  elif [ "$DISTRO" = "opensuse" ]; then
    zypper install -yn -t pattern xfce
    zypper install -yn xset xfce4-terminal xclip xfce4-notifyd
    zypper remove -yn xfce4-power-manager
    get_rid_of_policykit_error
fi

if grep -q Jammy /etc/os-release; then
  apt-get purge -y xfce4-screensaver
fi

if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum clean all
elif [ "${DISTRO}" == "oracle8" ]; then
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper clean --all
else
  apt-get purge -y pm-utils xscreensaver*
  apt-get clean -y
fi

if [[ "${DISTRO}" == @(centos|oracle7|oracle8) ]]; then
  config_xinit_disable_screensaver
else
  replace_default_xinit
  config_xinit_disable_screensaver
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
