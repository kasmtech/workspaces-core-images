#!/bin/sh
set -e
# bwrap wrapper: bypass bubblewrap sandboxing.
# Privileged containers (seccomp=unconfined, sysbox) allow bwrap to
# fully enforce namespace/seccomp isolation, which breaks glycin's
# image loaders. This wrapper strips all bwrap-specific flags and
# exec's the target command directly.

while [ $# -gt 0 ]; do
  case "$1" in
    # 0-arg flags
    --help|--version) shift ;;
    --unshare-user|--unshare-user-try|--unshare-ipc) shift ;;
    --unshare-pid|--unshare-net|--unshare-uts) shift ;;
    --unshare-cgroup|--unshare-cgroup-try|--unshare-all) shift ;;
    --share-net|--disable-userns|--assert-userns-disabled) shift ;;
    --clearenv|--new-session|--die-with-parent|--as-pid-1) shift ;;
    # 1-arg flags
    --args|--argv0|--userns|--userns2|--pidns) shift 2 ;;
    --uid|--gid|--hostname|--chdir|--unsetenv) shift 2 ;;
    --lock-file|--sync-fd|--perms|--size) shift 2 ;;
    --remount-ro|--proc|--dev|--tmpfs|--mqueue|--dir) shift 2 ;;
    --seccomp|--add-seccomp-fd|--exec-label|--file-label) shift 2 ;;
    --block-fd|--userns-block-fd|--info-fd|--json-status-fd) shift 2 ;;
    --cap-add|--cap-drop|--level-prefix) shift 2 ;;
    # 2-arg flags
    --setenv|--bind|--bind-try|--dev-bind|--dev-bind-try) shift 3 ;;
    --ro-bind|--ro-bind-try|--file|--bind-data|--ro-bind-data) shift 3 ;;
    --symlink|--chmod) shift 3 ;;
    # 3-arg flags
    --overlay|--tmp-overlay|--ro-overlay) shift 4 ;;
    # end-of-options marker
    --) shift; break ;;
    # first unrecognized arg is the target command
    *) break ;;
  esac
done

exec "$@"