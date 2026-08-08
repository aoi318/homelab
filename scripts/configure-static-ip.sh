#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <interface> <ipv4-cidr> <gateway-ipv4> <dns-ipv4>" >&2
  exit 64
fi

interface="$1"
ipv4_cidr="$2"
gateway_ipv4="$3"
dns_ipv4="$4"
mac_address="$(cat "/sys/class/net/${interface}/address")"

install -m 0644 /dev/null /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
printf '%s\n' 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

rm -f /etc/netplan/50-cloud-init.yaml
cat > /etc/netplan/99-homelab-static.yaml <<EOF
network:
  version: 2
  ethernets:
    ${interface}:
      match:
        macaddress: ${mac_address}
      set-name: ${interface}
      addresses:
        - ${ipv4_cidr}
      routes:
        - to: default
          via: ${gateway_ipv4}
      nameservers:
        addresses:
          - ${dns_ipv4}
EOF

chmod 0600 /etc/netplan/99-homelab-static.yaml
netplan generate
netplan apply
