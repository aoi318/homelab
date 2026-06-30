#!/bin/bash
# step5-client.sh
# Phase 1 / Step 5: db/web/mon/ca の各クライアントVMを infra01 基盤に向ける。
#   - DNS    : netplan で nameservers=infra01 / search=lab.local、IPv6 RA 無効化(方式B)
#   - NTP    : chrony を infra01 のみ参照(公開NTSプールは無効化)
#   - syslog : 全ログを infra01 の TCP 514 へ転送
#   - ufw    : deny incoming / allow ssh のみ -> enable
#   - sshd   : root直接ssh無効 / パスワード認証無効
#
# 特徴: 冪等・ホスト非依存(MAC/IPは現状を保持)。各VMで実行する。
# 実行例(デスクトップ WSL2 から、踏み台経由):
#   for h in db01 web01 mon01 ca01; do
#     wsl ssh "$h" 'bash -s' < scripts/step5-client.sh
#   done
set -euo pipefail

INFRA=192.168.10.10
HN=$(hostname -f)
NPF=/etc/netplan/50-cloud-init.yaml

echo "########## Step5 client setup on ${HN} ##########"

############################################
# 1) sshd hardening (接続影響なし)
############################################
echo "=== [1/5] sshd hardening ==="
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'CONF'
# Step 5: SSH hardening (manual now, Ansible later)
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
CONF
sudo sshd -t
sudo systemctl reload ssh 2>/dev/null || sudo systemctl reload ssh.service 2>/dev/null || true
sudo sshd -T | grep -iE '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication) ' | sed 's/^/    /'

############################################
# 2) rsyslog -> infra01 (TCP514, 信頼性キュー)
############################################
echo "=== [2/5] rsyslog forward ==="
sudo tee /etc/rsyslog.d/10-forward.conf >/dev/null <<CONF
# Step 5: forward all logs to infra01 over TCP 514
*.* action(type="omfwd"
           target="${INFRA}" port="514" protocol="tcp"
           action.resumeRetryCount="-1"
           queue.type="linkedList" queue.size="10000")
CONF
sudo rsyslogd -N1
sudo systemctl restart rsyslog
logger -t step5test "client setup ${HN} $(date -Is)"
echo "    rsyslog active=$(systemctl is-active rsyslog)"

############################################
# 3) chrony -> infra01 のみ
############################################
echo "=== [3/5] chrony -> infra01 ==="
if [ -f /etc/chrony/sources.d/ubuntu-ntp-pools.sources ]; then
  sudo mv -f /etc/chrony/sources.d/ubuntu-ntp-pools.sources \
             /etc/chrony/sources.d/ubuntu-ntp-pools.sources.disabled
fi
sudo tee /etc/chrony/sources.d/infra.sources >/dev/null <<CONF
# Step 5: use infra01 as the lab NTP server
server ${INFRA} iburst prefer
CONF
sudo systemctl restart chrony

############################################
# 4) ufw (接続影響あり: ssh許可してから enable)
############################################
echo "=== [4/5] ufw ==="
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'ssh'
sudo ufw --force enable
sudo ufw status verbose | grep -E 'Status|Default|22/tcp' | sed 's/^/    /'

############################################
# 5) netplan: DNS=infra01 / search=lab.local / accept-ra:false
#    (cloud-init の network 再生成を止めてから書換。MAC/IPは現状保持)
############################################
echo "=== [5/5] netplan DNS -> infra01 ==="
sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg >/dev/null <<'CONF'
network: {config: disabled}
CONF
[ -f "${NPF}.orig" ] || sudo cp -a "$NPF" "${NPF}.orig"
sudo python3 - "$NPF" "$INFRA" <<'PY'
import sys, yaml
path, infra = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = yaml.safe_load(f)
for _, dev in cfg['network']['ethernets'].items():
    dev['nameservers'] = {'addresses': [infra], 'search': ['lab.local']}
    dev['accept-ra'] = False
with open(path, 'w') as f:
    yaml.safe_dump(cfg, f, default_flow_style=False, sort_keys=False)
PY
sudo chmod 600 "$NPF"
sudo netplan generate
sudo netplan apply   # 静的IPv4は不変なので既存sshセッションは維持される
sleep 3
resolvectl status | grep -E 'Current DNS Server|DNS Servers|DNS Domain' | sed 's/^/    /'

echo "########## done: ${HN} ##########"
