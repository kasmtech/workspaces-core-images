#!/usr/bin/env bash
set -e

echo "Installing Cursors"
cd $INST_SCRIPTS/cursors

tar -xzf cursor-aero.tar.gz -C /usr/share/icons/
tar -xzf cursor-bridge.tar.gz -C /usr/share/icons/
tar -xzf cursor-capitaine-r4.tar.gz -C /usr/share/icons/
