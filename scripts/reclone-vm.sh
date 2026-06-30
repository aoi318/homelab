#!/bin/bash
# reclone-vm.sh
# 1台のVMをテンプレート(9000)から作り直す。Step 8(再現性検証) / 障害復旧用。
# 実行場所: Proxmox ホスト(pve01)。
#   使い方: reclone-vm.sh <vmid> <name> <ip-last-octet-付きIP>
#   例:     reclone-vm.sh 114 ca01 192.168.10.14
# 既存VMがあれば stop -> destroy してから clone する(破壊的)。
set -euo pipefail
export PATH=$PATH:/usr/sbin:/sbin

VMID=${1:?vmid}; NAME=${2:?name}; IP=${3:?ip}
TEMPLATE_ID=9000
GATEWAY=192.168.10.1
POOL=infra-lab
SNIPPET="user-data-${NAME}.yaml"

if qm status "$VMID" &>/dev/null; then
  echo "[*] 既存 $VMID を停止・削除"
  qm stop "$VMID" 2>/dev/null || true
  for i in $(seq 1 30); do
    [ "$(qm status "$VMID" 2>/dev/null | awk '{print $2}')" = "stopped" ] && break
    sleep 1
  done
  qm destroy "$VMID"
fi

echo "[*] テンプレートから clone"
qm clone "$TEMPLATE_ID" "$VMID" --name "$NAME"
qm set "$VMID" --ipconfig0 "ip=${IP}/24,gw=${GATEWAY}"
qm set "$VMID" --cicustom "user=local:snippets/${SNIPPET}"
# cloud-init CDROM を再生成(cicustom反映)
qm set "$VMID" --delete ide2
qm set "$VMID" --ide2 local-lvm:cloudinit
pvesh set "/pools/${POOL}" -vms "$VMID" 2>/dev/null || true
qm start "$VMID"
echo "[*] $NAME ($VMID) 起動。cloud-init 完了まで 60-90 秒。"
