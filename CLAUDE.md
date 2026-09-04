# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**workspaces-core-images** produces the base ("core") Docker images from which every other Kasm Workspaces image is derived. These images bundle a Linux desktop environment, a VNC/browser-access stack (KasmVNC), and the in-container wiring that lets a workspace integrate with the Kasm platform (audio, clipboard, uploads/downloads, webcam, microphone, printing, profile sync, session recording, etc.).

The output is a family of images published as `kasmweb/core-<distro>:<tag>` (e.g. `kasmweb/core-ubuntu-noble`, `kasmweb/core-fedora-41`, `kasmweb/core-alpine-321`). Downstream repos — notably `workspaces-images` (single-app images like Chrome, Firefox, VS Code) and customer-built workspaces — inherit `FROM` these core images.

Related repos in the broader Kasm system:

- `kasm_backend` (parent of this clone) — the backend services that orchestrate workspaces
- `workspaces-images` — application-specific images built on top of these cores
- `KasmVNC` — the VNC server that renders the desktop to a browser
- `kasm_squid_adapter`, `kasm_upload_service`, `kasm_printer_service`, `kasm-webcam-server`, `kasm-gamepad-server`, `profile-sync`, `kasm_smartcard_bridge`, `kasm_websocket_relay`, `kasm_audio_input_server`, `kasm_recorder_service`, `kasm-squid-builder` — component binaries pulled in at image build time

## Repository Layout

```
workspaces-core-images/
├── dockerfile-kasm-core              # Debian/Ubuntu family (default)
├── dockerfile-kasm-core-alpine       # Alpine
├── dockerfile-kasm-core-centos       # CentOS 7
├── dockerfile-kasm-core-fedora       # Fedora
├── dockerfile-kasm-core-kasmos       # KasmOS (Debian bookworm slim)
├── dockerfile-kasm-core-oracle       # Oracle Linux / RHEL / Rocky / Alma
├── dockerfile-kasm-core-suse         # openSUSE
│
├── src/
│   ├── common/                       # Shared across all distros
│   │   ├── install/                  # kasm_vnc, profile_sync configs
│   │   ├── resources/images/         # Backgrounds, icons, branding
│   │   ├── scripts/kasm_hook_scripts # Session lifecycle hooks (see below)
│   │   └── startup_scripts/          # vnc_startup.sh and friends
│   │
│   ├── ubuntu/                       # Ubuntu/Debian install scripts
│   │   ├── install/                  # One subdir per feature (audio, webcam, …)
│   │   ├── xfce/                     # XFCE desktop configs
│   │   └── icewm/                    # IceWM (lightweight alt) configs
│   │
│   ├── alpine/  centos/  fedora*/  kasmos/
│   ├── opensuse/  oracle7/ oracle8/ oracle9/
│   ├── rhel9/  rockylinux*/  almalinux*/
│   ├── parrotos6/  kali/             # Distro-specific install scripts
│
├── ci-scripts/                       # GitLab CI build/test/manifest tooling
│   ├── build.sh, test.sh             # Called per matrix row from .gitlab-ci.yml
│   ├── template-gitlab.py            # Jinja2 renderer for gitlab-ci.template
│   ├── template-vars.yaml            # Matrix of images to build + change-file rules
│   ├── gitlab-ci.template            # The actual CI config, rendered dynamically
│   ├── manifest.sh                   # Multi-arch manifest assembly
│   ├── scan/, vulnerability-filter.rego  # Trivy scan + Rego filtering
│   └── readme.sh, quay_readme.sh     # Dockerhub/Quay README publishing
│
├── bin/                              # Prebuilt helpers shipped into images
│   ├── intel-gpu-dri3, intel-gpu-virtualgl, intel-gpu-zink
│
├── docs/core-<distro>/               # Per-image README/description for Dockerhub
│                                     # (README.md, description.txt, demo.txt)
│
└── kasm-desktop-kde/                 # KDE desktop variant (WIP/placeholder)
```

## What's inside a core image

Every dockerfile follows the same shape — a series of `COPY` + `RUN bash $INST_SCRIPTS/<feature>/install_<feature>.sh` blocks — and installs (roughly in order):

1. **Package rules** — apt/yum/apk pinning and repo setup
2. **Base tools** — curl, jq, sudo, xz, etc.
3. **Fonts** — custom Kasm fonts + distro fonts
4. **Desktop environment** — XFCE (default), IceWM (lightweight), or KDE variant
5. **KasmVNC** — the browser-accessible VNC server (heart of the image)
6. **profile_sync** — persists user profile to object storage between sessions
7. **kasm_upload_server** — handles browser-initiated file uploads/downloads
8. **Audio output** (`kasm_websocket_relay`) — PulseAudio → WebSocket bridge for audio streaming
9. **Audio input** (`kasm_audio_input_server`) — microphone passthrough from browser
10. **Gamepad** (`kasm_gamepad_server`) — HID passthrough from browser
11. **Webcam** (`kasm_webcam_server`) — virtual webcam device
12. **Printer** (`kasm_printer_service`) — CUPS + start_cups.sh
13. **Recorder** (`kasm_recorder_service`) — session recording via FFmpeg + KasmVNC capture
14. **Cursors** — custom cursor theme
15. **Squid** (`kasm_squid_adapter` + `kasm-squid-builder`) — per-session egress proxy
16. **Smartcard** (`kasm_smartcard_bridge`) — CCID/pcscd passthrough
17. **NVIDIA / VirtualGL** — optional GPU acceleration
18. **Hook scripts** — `src/common/scripts/kasm_hook_scripts/` (see below)
19. **Cleanup** — strip caches, man pages, locales to shrink layers

Environment variables set by every core image:

- `HOME=/home/kasm-default-profile` — template profile copied to `/home/kasm-user` at startup
- `STARTUPDIR=/dockerstartup` — houses `vnc_startup.sh` and the hook scripts
- `INST_SCRIPTS=/dockerstartup/install` — scratch dir used only during build (removed after each install)
- `KASM_VNC_PATH=/usr/share/kasmvnc`

## Runtime lifecycle

Containers start at `vnc_startup.sh` (in `src/common/startup_scripts/`). It:

1. Logs to the Kasm API via `KASM_API_JWT` / `KASM_API_HOST` / `KASM_API_PORT` if set
2. Regenerates the container user (`generate_container_user`) so UIDs match the workspace config
3. Starts dbus, PulseAudio, KasmVNC, the desktop (XFCE by default, overridable via `START_XFCE4` / `START_ICEWM` / etc.), kasm_upload_server, the squid adapter, cups, profile_sync, the recorder
4. Invokes lifecycle hook scripts in `src/common/scripts/kasm_hook_scripts/` at the right moments:
   - `kasm_post_run_root.sh`   — runs as root after core services are up
   - `kasm_post_run_user.sh`   — runs as `kasm-user` after login
   - `kasm_pre_shutdown_root.sh` / `kasm_pre_shutdown_user.sh` — graceful teardown
   - `kasm_end_session_recoverable.sh` — for persistent/resumable sessions
5. Tails the running processes; exits when the main desktop process dies

Downstream images can override hooks by placing replacements at the same path during their own build.

## Build system

### Local / manual build

The README shows the user-facing form:

```bash
sudo docker run --rm -it --shm-size=512m -p 6901:6901 \
  -e VNC_PW=password --build-arg START_XFCE4=1 \
  kasmweb/core-ubuntu-noble:<tag>
```

For building from source, each dockerfile takes these build args:

- `BASE_IMAGE`  — e.g. `ubuntu:24.04`, `fedora:41`, `alpine:3.21`
- `DISTRO`      — selects which `src/<distro>/` tree of install scripts to copy
- `BG_IMG`      — which wallpaper from `src/common/resources/images/` to use
- `EXTRA_SH`    — optional extra install script (defaults to `noop.sh`)

```bash
docker build \
  -f dockerfile-kasm-core \
  --build-arg BASE_IMAGE=ubuntu:24.04 \
  --build-arg DISTRO=ubuntu \
  --build-arg BG_IMG=bg_kasm.png \
  -t kasmweb/core-ubuntu-noble:dev .
```

### GitLab CI

The CI pipeline is **dynamically generated**:

1. `template-gitlab.py` reads `template-vars.yaml` (matrix of image names, base images, dockerfiles, change-file globs)
2. It renders `gitlab-ci.template` (Jinja2) into a `.gitlab-ci-child.yml`
3. GitLab runs that child pipeline with stages: build → test → scan → manifest → release

Key scripts invoked from the template:

- `ci-scripts/build.sh NAME1 NAME2 BASE BG DISTRO DOCKERFILE` — per-arch build, pushes to private image cache
- `ci-scripts/test.sh ... ARCH AWS_ID AWS_KEY` — spins up an EC2 instance to smoke-test the image with the Playwright tester below
- `ci-scripts/manifest.sh` / `weekly-manifest.sh` — joins x86_64 + aarch64 into a single multi-arch manifest
- `ci-scripts/scan/` + `vulnerability-filter.rego` — Trivy CVE scan with Rego-based allowlist
- `ci-scripts/readme.sh`, `quay_readme.sh` — push the per-image `docs/core-*/README.md` to Dockerhub/Quay

`FILE_LIMITS` gating: on feature branches the pipeline only builds images whose `files:` globs in `template-vars.yaml` actually changed. `develop` and `release/*` branches build everything. `UNIVERSAL_CHANGE_FILES` (at the top of `template-vars.yaml`) is the set of paths that force rebuilding every image — edit those conservatively.

**Playwright tester (DEVOPS-74):** every `test_*` job runs the kasmweb Playwright `*.image-spec.ts` suite in `test.sh`, against a `KASMWEB_VERSION` checkout on a `node:24` test job image (Playwright's bundled Chromium needs glibc) — same mechanism ported from `workspaces-images`. This replaced the legacy Selenium `kasm-tester` suite, which has been removed. Related variables (`.gitlab-ci.yml`):

- `TEST_INSTALLER_ROLLING` — rolling `develop` install bundle, since the specs need post-1.19.0 API/UI changes.
- `KASMWEB_VERSION` — kasmweb ref the specs are cloned from; pinned to a feature branch until DEVOPS-74 merges to `develop`.
- `SKIP_DB_SNAPSHOT_ON_FAILURE` / `SKIP_TRACE_ON_FAILURE` — default `true` to bound `pg_dump`/`trace.zip` artifact size across the many per-image runs this pipeline accumulates; set to `false` on a specific pipeline run to get full diagnostics for a failure.

## Common tasks

**Add support for a new distro version:**

1. Add a block to `template-vars.yaml` (`images:` list) with its name, base image, dockerfile, and change-file globs
2. Create `src/<distro>/install/` trees if a new family (usually just reuse ubuntu/fedora/alpine/etc.)
3. Add `docs/core-<distro>/` with `README.md`, `description.txt`, `demo.txt`
4. Verify change-file globs pick up the right paths on feature-branch builds

**Add a new in-container feature (e.g., new passthrough device):**

1. Create `src/ubuntu/install/<feature>/install_<feature>.sh` (and peers for other distro families)
2. Add `COPY` + `RUN bash $INST_SCRIPTS/<feature>/install_<feature>.sh` to every relevant dockerfile
3. Wire the feature into `src/common/startup_scripts/vnc_startup.sh` if it needs a runtime process
4. Add the path to `UNIVERSAL_CHANGE_FILES` in `template-vars.yaml` so all images rebuild on change

**Debug a failing image at runtime:**

- Start with `-e VNC_PW=password` and connect to `https://<host>:6901` as `kasm_user` / `password`
- Check `/var/log/kasm-*` and the container's stdout (vnc_startup.sh logs go there)
- If running inside a real Kasm deployment, logs are also forwarded to the Kasm API via the `KASM_API_JWT` path in vnc_startup.sh

## Conventions / gotchas

- **Install scripts run at build time only.** `$INST_SCRIPTS` is removed after each install step — do not reference it from runtime code.
- **Downstream images inherit everything.** Be conservative when adding packages; a 50MB addition to a core image fans out across every application image.
- **Multi-arch.** Every dockerfile must work on both `amd64` and `arm64`. Shell out to `$(arch)` or `dpkg --print-architecture` rather than hardcoding.
- **No secrets in images.** Anything in `$HOME/kasm-default-profile` ships in the public image.
- **Cleanup matters.** Each feature's install script is expected to remove its own build-time caches before the layer closes (`apt clean`, `rm -rf /var/lib/apt/lists/*`, etc.) — missing cleanup bloats every downstream image.
- **`dockerfile-kasm-core` is the reference.** The other dockerfiles are variants with equivalent structure; when adding a feature, update them all in the same commit to avoid drift.

## License

See `LICENSE.md` (Kasm Technologies license, not OSS).
