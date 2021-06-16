#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

mkdir -p $STARTUPDIR/audio_input
if [ "$DISTRO" = centos ]; then
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/17b516ead4504f180358bf11bd735cb5eb28d032/kasm_audio_input_server_centos_core_feature_KASM-1476_centos_build_microphone_server.17b516.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/
else
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_audio_input_server/627e9301c4140cd70c82a798b33c2acae2860e28/kasm_audio_input_server_develop.627e93.tar.gz | tar -xvz -C $STARTUPDIR/audio_input/
fi
