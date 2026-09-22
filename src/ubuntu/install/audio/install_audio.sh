#!/usr/bin/env bash
### every exit != 0 fails the script
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
echo "Install Audio Requirements"
if [[ "${DISTRO}" == "oracle8" ]]; then
  dnf install -y curl git
  dnf config-manager --set-enabled ol8_codeready_builder
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
  dnf install -y ffmpeg pulseaudio-utils
elif [[ "${DISTRO}" == @(oracle9|rhel9) ]]; then
  dnf install -y --allowerasing curl git
  if [[ "${DISTRO}" == "oracle9" ]]; then
    dnf config-manager --set-enabled ol9_codeready_builder
  fi
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [[ "${DISTRO}" == @(rockylinux9|almalinux9) ]]; then
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [[ "${DISTRO}" == @(rockylinux8|almalinux8) ]]; then
  dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio-utils pulseaudio
elif [[ "${DISTRO}" == "fedora42" ]]; then
  dnf install -y curl git
  dnf-3 localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [[ "${DISTRO}" == "fedora43" ]]; then
  dnf install -y curl git
  dnf-3 localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
  dnf install -y --allowerasing ffmpeg pulseaudio pulseaudio-utils
elif [[ "${DISTRO}" == opensuse ]]; then
  zypper install -ny curl git
  if grep -q "16" /etc/os-release; then
    # Packman provides ffmpeg-4 compiled with x264/x265 support (required by KasmVNC
    # software encoder). The main repo ffmpeg-4 lacks those codecs.
    zypper addrepo -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/' packman
    zypper --gpg-auto-import-keys refresh packman
    zypper install -yn --allow-vendor-change ffmpeg-4 pulseaudio-utils \
    pipewire \
    pipewire-pulseaudio \
    wireplumber
    # Lock ffmpeg-7 — Packman provides it too and it breaks KasmVNC's libavcodec
    zypper addlock ffmpeg-7
    # Remove the Packman repo so later build steps can't accidentally pull more packages
    zypper removerepo packman
    # pipewire-pulseaudio replaces pulseaudio on openSUSE 16; wrap the binary so
    # START_PULSEAUDIO=1 works — pipewire-pulse doesn't understand --start.
    cat > /usr/local/bin/pulseaudio <<'EOF'
#!/bin/bash
# PipeWire needs XDG_RUNTIME_DIR for its socket
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run/pulse}"
mkdir -p "$XDG_RUNTIME_DIR"
# Start the core PipeWire daemon if needed
pgrep -x pipewire > /dev/null 2>&1 || /usr/bin/pipewire &
sleep 0.5
# Start the WirePlumber session manager if needed
pgrep -x wireplumber > /dev/null 2>&1 || /usr/bin/wireplumber &
sleep 0.3
# Start the PulseAudio compatibility server if needed
pgrep -x pipewire-pulse > /dev/null 2>&1 || /usr/bin/pipewire-pulse &
# Wait for the PulseAudio compat socket to be available (up to 5s).
# pipewire-pulse may place the socket at $XDG_RUNTIME_DIR/pulse/native
# (e.g. /var/run/pulse/pulse/native) rather than $XDG_RUNTIME_DIR/native.
# If that happens, symlink it to /var/run/pulse/native so that
# PULSE_RUNTIME_PATH and PULSE_SERVER both work correctly.
for _i in $(seq 1 10); do
    [ -S /var/run/pulse/native ] && break
    if [ -S /var/run/pulse/pulse/native ]; then
        ln -sf /var/run/pulse/pulse/native /var/run/pulse/native
        break
    fi
    sleep 0.5
done
EOF
    chmod +x /usr/local/bin/pulseaudio
    # ffmpeg-4 installs as /usr/bin/ffmpeg-4; create /usr/bin/ffmpeg so that
    # vnc_startup.sh can call 'ffmpeg -f pulse ...' for audio streaming
    [[ -e /usr/bin/ffmpeg ]] || ln -s /usr/bin/ffmpeg-4 /usr/bin/ffmpeg
  fi
elif [[ "${DISTRO}" == "alpine" ]]; then
  apk add --no-cache \
    ffmpeg \
    ffplay \
    git \
    pulseaudio \
    pulseaudio-utils
else
  apt-get update
  apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    git \
    pulseaudio \
    pulseaudio-utils
fi

mkdir -p /var/run/pulse

WS_COMMIT_ID="f056f949e79a55217ec44c8fc4c79418ada0c05e"
WS_BRANCH="develop"
WS_COMMIT_ID_SHORT=$(echo "${WS_COMMIT_ID}" | cut -c1-6)

cd $STARTUPDIR
mkdir jsmpeg
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_websocket_relay/${WS_COMMIT_ID}/kasm_websocket_relay_${ARCH}_${WS_BRANCH}.${WS_COMMIT_ID_SHORT}.tar.gz | tar xz --strip 1 -C $STARTUPDIR/jsmpeg
chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux

if [[ "${DISTRO}" == "alpine" ]]; then
  # Alpine's gcompat shim doesn't implement fcntl64, so the glibc binary fails to load
  # Build a shim that forwards fcntl64() to musl's fcntl()
  apk add --no-cache --virtual .audio-build-deps gcc musl-dev
  cat > /tmp/fcntl64_compat.c << 'EOF'
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdarg.h>

/* fcntl()'s third argument varies by cmd: some commands take none, some an
 * int, some a pointer. Reading an argument that was never passed (or reading
 * an int slot as a pointer) is undefined behavior, so dispatch per command
 * instead of always assuming a pointer arg. Constants are guarded so this
 * still compiles if a given musl/Alpine version lacks a newer command. */
static int fcntl64_takes_no_arg(int cmd) {
    switch (cmd) {
#ifdef F_GETFD
    case F_GETFD:
#endif
#ifdef F_GETFL
    case F_GETFL:
#endif
#ifdef F_GETOWN
    case F_GETOWN:
#endif
#ifdef F_GETSIG
    case F_GETSIG:
#endif
#ifdef F_GETLEASE
    case F_GETLEASE:
#endif
#ifdef F_GETPIPE_SZ
    case F_GETPIPE_SZ:
#endif
#ifdef F_GET_SEALS
    case F_GET_SEALS:
#endif
        return 1;
    default:
        return 0;
    }
}

static int fcntl64_takes_int_arg(int cmd) {
    switch (cmd) {
#ifdef F_DUPFD
    case F_DUPFD:
#endif
#ifdef F_DUPFD_CLOEXEC
    case F_DUPFD_CLOEXEC:
#endif
#ifdef F_SETFD
    case F_SETFD:
#endif
#ifdef F_SETFL
    case F_SETFL:
#endif
#ifdef F_SETOWN
    case F_SETOWN:
#endif
#ifdef F_SETSIG
    case F_SETSIG:
#endif
#ifdef F_SETLEASE
    case F_SETLEASE:
#endif
#ifdef F_NOTIFY
    case F_NOTIFY:
#endif
#ifdef F_SETPIPE_SZ
    case F_SETPIPE_SZ:
#endif
#ifdef F_ADD_SEALS
    case F_ADD_SEALS:
#endif
        return 1;
    default:
        return 0;
    }
}

int fcntl64(int fd, int cmd, ...) {
    va_list ap;
    va_start(ap, cmd);

    if (fcntl64_takes_no_arg(cmd)) {
        va_end(ap);
        return fcntl(fd, cmd);
    }

    if (fcntl64_takes_int_arg(cmd)) {
        int arg = va_arg(ap, int);
        va_end(ap);
        return fcntl(fd, cmd, arg);
    }

    /* Everything else (F_GETLK/F_SETLK/F_SETLKW, F_OFD_*, F_GETOWN_EX/
     * F_SETOWN_EX, F_GET_RW_HINT/F_SET_RW_HINT, and any future/unknown
     * command) takes a pointer. */
    void *arg = va_arg(ap, void *);
    va_end(ap);
    return fcntl(fd, cmd, arg);
}
EOF
  gcc -shared -fPIC -o /usr/local/lib/fcntl64_compat.so /tmp/fcntl64_compat.c
  rm /tmp/fcntl64_compat.c
  apk del .audio-build-deps

  mv $STARTUPDIR/jsmpeg/kasm_audio_out-linux $STARTUPDIR/jsmpeg/kasm_audio_out-linux.bin
  cat > $STARTUPDIR/jsmpeg/kasm_audio_out-linux << 'WRAPPER'
#!/bin/sh
exec env LD_PRELOAD=/usr/local/lib/fcntl64_compat.so \
  /dockerstartup/jsmpeg/kasm_audio_out-linux.bin "$@"
WRAPPER
  chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux
  chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux.bin
fi
