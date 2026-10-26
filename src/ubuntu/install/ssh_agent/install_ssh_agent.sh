#!/bin/bash
### every exit != 0 fails the script
set -ex

if [ ! -f "$STARTUPDIR/smartcard/kasm_ssh_agent_bridge" ]; then
  echo "ERROR: $STARTUPDIR/smartcard/kasm_ssh_agent_bridge not found - did install_smartcard.sh run first?" >&2
  exit 1
fi

mkdir -p $STARTUPDIR/ssh_agent
mv $STARTUPDIR/smartcard/kasm_ssh_agent_bridge $STARTUPDIR/ssh_agent/kasm_ssh_agent_bridge
cp $STARTUPDIR/smartcard/kasm_smartcard_bridge.version $STARTUPDIR/ssh_agent/kasm_ssh_agent_bridge.version

mkdir -p /etc/profile.d
cat > /etc/profile.d/kasm_ssh_agent.sh <<'EOF'
# Kasm SSH-agent forwarding - see install_ssh_agent.sh.
#
# Gated on the socket file's existence rather than $KASM_SVC_SSH_AGENT:
# vnc_startup.sh sets that variable without `export`, so it is only visible
# within vnc_startup.sh's own process tree and never reaches a shell started
# outside it. The socket only exists at all when start_ssh_agent() actually
# ran, so testing for it directly is both simpler and independent of env var
# propagation.
#
# Keep this path in sync with $KASM_SSH_AGENT_SOCK in vnc_startup.sh, which
# explains why the socket lives here and not under $STARTUPDIR.
if [ -S /tmp/.kasm-ssh-agent/ssh-agent.sock ]; then
  export SSH_AUTH_SOCK=/tmp/.kasm-ssh-agent/ssh-agent.sock
fi
EOF
chmod 644 /etc/profile.d/kasm_ssh_agent.sh

for sys_bashrc in /etc/bash.bashrc /etc/bashrc; do
  if [ -f "$sys_bashrc" ] && ! grep -q 'kasm_ssh_agent.sh' "$sys_bashrc"; then
    cat >> "$sys_bashrc" <<'EOF'

# Kasm SSH-agent forwarding (see install_ssh_agent.sh). /etc/profile.d/ is
# login-shell-only; this covers interactive non-login shells such as terminals.
if [ -f /etc/profile.d/kasm_ssh_agent.sh ]; then
  . /etc/profile.d/kasm_ssh_agent.sh
fi
EOF
  fi
done
