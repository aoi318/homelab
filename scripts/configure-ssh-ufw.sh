#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <admin-ipv4>" >&2
  exit 64
fi

admin_ipv4="$1"

install -m 0755 -d /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/10-homelab.conf <<EOF
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sshd -t
systemctl reload ssh

ufw default deny incoming
ufw default allow outgoing
ufw allow from "${admin_ipv4}" to any port 22 proto tcp
ufw --force enable
