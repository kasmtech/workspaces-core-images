#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

get_rid_of_policykit_error() {
  rm /etc/xdg/autostart/xfce-polkit.desktop
}

disable_epel_nss_wrapper_that_breaks_firefox() {
  yum-config-manager --setopt=epel.exclude=nss_wrapper --save
}

get_rid_of_xfce_battery_widget() {
  yum remove -y xfce4-power-manager
}

echo "Install Xfce4 UI components"
if [ "$DISTRO" != "centos" ]; then
  apt-get update
fi

if [ "${DISTRO}" == "kali" ]  ;
then
    apt-get install -y supervisor kali-desktop-xfce
    # Disable the power management plugin Xfce4 from starting and displaying an error
    PLUGIN_ID=$(grep  power-manager-plugin /etc/xdg/xfce4/panel/default.xml | perl -n -e '/plugin-(\d+)/ && print $1')
    sed -i "s@<value type=\"int\" value=\"${PLUGIN_ID}\"/>@@g" /etc/xdg/xfce4/panel/default.xml
  elif [ "$DISTRO" = "ubuntu" ]; then
    apt-get install -y supervisor xfce4 xfce4-terminal xterm
  elif [ "$DISTRO" = "centos" ]; then
    yum install -y epel-release
    disable_epel_nss_wrapper_that_breaks_firefox
    yum groupinstall xfce xterm -y
    get_rid_of_policykit_error
    get_rid_of_xfce_battery_widget
fi


if [ "$DISTRO" = "centos" ]; then
  yum clean all
else
  apt-get purge -y pm-utils xscreensaver*
  apt-get clean -y
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
