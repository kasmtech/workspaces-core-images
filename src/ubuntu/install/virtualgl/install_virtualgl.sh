if [ "$DISTRO" = "ubuntu" ]; then
  #update mesa to latest
  add-apt-repository ppa:kisak/kisak-mesa
  apt full-upgrade -y

  #install virtualgl
  wget https://sourceforge.net/projects/virtualgl/files/2.6.95%20%283.0rc1%29/virtualgl_2.6.95_amd64.deb -P /tmp
  set +e
  dpkg -i /tmp/virtualgl_*amd64.deb
  set -e
  apt install -f -y
  rm /tmp/virtualgl_*amd64.deb
fi
