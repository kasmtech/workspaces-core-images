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

echo "Install Openbox UI components"
if [[ "${DISTRO}" != @(centos|oracle7|oracle8|opensuse|fedora37|fedora38|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
  apt-get update
fi

if [[ "$DISTRO" = @(ubuntu|debian|parrotos5) ]]; then
  apt-get install -y x11-utils
  apt-get install -y --no-install-recommends \
    curl \
    dbus-x11 \
    openbox \
    x11-xserver-utils \
    xclip \
    xterm
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
elif [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  if [ "${DISTRO}" == centos ]; then
    yum install -y epel-release
  else
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  
  fi
  disable_epel_nss_wrapper_that_breaks_firefox
  yum install -y \
    curl \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [ "$DISTRO" = "oracle8" ]; then
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf install -y \
    curl \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [ "$DISTRO" = "oracle9" ]; then
  dnf config-manager --set-enabled ol9_codeready_builder
  dnf config-manager --set-enabled ol9_distro_builder
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf install -y \
    curl \
    dbus-x11 \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [[ "$DISTRO" == @(rockylinux9|almalinux9) ]]; then
  dnf config-manager --set-enabled crb
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  dnf install -y \
    curl \
    dbus-x11 \
    gvfs \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [[ "$DISTRO" == @(rockylinux8|almalinux8) ]]; then
  dnf config-manager --set-enabled powertools
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf install -y \
    curl \
    dbus-x11 \
    gvfs \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [ "$DISTRO" = "opensuse" ]; then
  zypper install -yn \
    curl \
    gvfs \
    openbox \
    xclip \
    xset \
    xterm
elif [[ "$DISTRO" = @(fedora37|fedora38) ]]; then
  dnf install -y \
    curl \
    gvfs \
    openbox \
    wmctrl \
    xclip \
    xset \
    xterm
elif [ "$DISTRO" = "alpine" ]; then
  apk add --no-cache \
    curl \
    dbus-x11 \
    gvfs \
    mesa \
    mesa-dri-gallium \
    mesa-gl \
    openbox \
    xterm
fi

if [[ "${DISTRO}" != @(centos|oracle7|oracle8|fedora37|fedora38|oracle9|rockylinux9|rockylinux8|almalinux8|almalinux9|alpine) ]]; then
  replace_default_xinit
  if [ "${START_XFCE4}" == "1" ] ; then
    replace_default_99x11_common_start
  fi
fi

cat >/usr/bin/desktop_ready <<EOL
#!/usr/bin/env bash
if [ -z \${START_DE+x} ]; then \
  START_DE="xfce4-session"
fi
until pids=\$(pidof \${START_DE}); do sleep .5; done
EOL
chmod +x /usr/bin/desktop_ready

# Support desktop icon trust
cat >>/etc/xdg/autostart/desktop-icons.desktop<<EOL
[Desktop Entry]
Type=Application
Name=Desktop Icon Trust
Exec=/dockerstartup/trustdesktop.sh
EOL
chmod +x /etc/xdg/autostart/desktop-icons.desktop

# OpenBox tweaks
sed -i \
  's/NLIMC/NLMC/g' \
  /etc/xdg/openbox/rc.xml
