#!/bin/bash
if [ ! -f $HOME/.local/share/gvfs-metadata/home ]; then
  for f in $HOME/Desktop/*.desktop; do 
    gio set -t string "$f" metadata::xfce-exe-checksum "$(sha256sum "$f" | awk '{print $1}')" || :
  done
fi
