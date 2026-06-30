#!/bin/bash
# clone-vms.sh
# テンプレート(9000)から各VMをcloneして初期設定する
# 実行場所: Proxmoxホスト

TEMPLATE_ID=9000
SSH_KEY=/root/id_ed25519.pub
GATEWAY=192.168.10.1
SNIPPETS_DIR=/var/lib/vz/snippets
POOL=infra-lab

declare -A VMS=(
    [110]="infra01:192.168.10.10"
    [111]="db01:192.168.10.11"
    [112]="web01:192.168.10.12"
    [113]="mon01:192.168.10.13"
    [114]="ca01:192.168.10.14"
)

# user-dataファイルを各VM用に生成
generate_user_data() {
    local name=$1
    cat > ${SNIPPETS_DIR}/user-data-${name}.yaml << EOF
#cloud-config
hostname: ${name}
fqdn: ${name}.lab.local
manage_etc_hosts: true
users:
  - name: admin
    primary_group: admin
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat ${SSH_KEY})
EOF
    echo "Generated user-data-${name}.yaml"
}

# プールが存在しなければ作成
if ! pvesh get /pools/${POOL} &>/dev/null; then
    pvesh post /pools --poolid ${POOL}
    echo "Created pool: ${POOL}"
fi

# VMをcloneして設定
for vmid in $(echo "${!VMS[@]}" | tr ' ' '\n' | sort); do
    name="${VMS[$vmid]%%:*}"
    ip="${VMS[$vmid]##*:}"

    echo "=== Creating VM $vmid ($name, $ip) ==="

    # user-data生成
    generate_user_data $name

    # clone
    qm clone $TEMPLATE_ID $vmid --name $name

    # ネットワーク設定
    qm set $vmid --ipconfig0 ip=${ip}/24,gw=${GATEWAY}

    # cloud-init設定
    qm set $vmid --cicustom "user=local:snippets/user-data-${name}.yaml"

    # CDROM再生成(cicustomを反映させる)
    qm set $vmid --delete ide2
    qm set $vmid --ide2 local-lvm:cloudinit

    # プールに追加
    pvesh set /pools/${POOL} -vms $vmid
    echo "Added VM $vmid to pool ${POOL}"

    # 起動
    qm start $vmid

    echo "Done: $name ($vmid)"
done

echo ""
echo "All VMs created and added to pool ${POOL}."
echo "Wait 60-90 seconds for cloud-init to complete."
echo "Then verify with:"
echo "  ssh -i ~/.ssh/id_ed25519 admin@<ip>"