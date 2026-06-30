# homelab

学習目的の個人homelabプロジェクト。
Proxmox上のVMから始め、Kubernetes化、フルスタックの監視基盤、GitOpsまでを段階的に構築する。

## 状態

**Phase 1 完了** — 基盤（cloud-init/Ansible・内部DNS(unbound)/NTP(chrony)・rsyslogログ集約・ufw・SSH強化）を構築し、Ansibleで冪等管理。次は Phase 2。

| Phase | 内容 | 状態 |
| ----- | ---- | ---- |
| 0 | 設計・ハードウェア準備 | ✅ 完了 |
| 1 | 基盤構築（DNS/NTP/syslog/FW/SSH・Ansible化・再現性検証） | ✅ 完了 |
| 2 | Web + DB + 自前TLS（PostgreSQL/Redis/Nginx/step-ca） | 🚧 これから |
| 3 | Docker化 | – |
| 4 | 監視（Prometheus/Grafana/Loki/Tempo・SLO/エラーバジェット） | – |
| 5 | CI/CD（GitHub Actions → ghcr.io → pull型デプロイ） | – |
| 6 | Kubernetes（k3s + Argo CD + Cilium） | – |

## 技術スタック

- **ハイパーバイザ**: Proxmox VE 9
- **プロビジョニング**: cloud-init + Ansible
- **アプリケーション**: Go (URL短縮API)
- **コンテナ**: Docker
- **オーケストレーション**: k3s + Helm + Argo CD
- **オブザーバビリティ**: Prometheus + Grafana + Loki + Tempo
- **CI/CD**: GitHub Actions + ghcr.io

## リポジトリ構成

```
ansible/   # 構成管理 (roles: common, dns/ntp/log の client・server)
scripts/   # プロビジョニング補助 (VM clone, lab DNS切替, ログ整理, VM再作成)
docs/      # アーキテクチャと構成図
```

## ドキュメント

- `docs/architecture.md`: 全体構成と設計判断
- `docs/diagrams/vm-layout.md`: VM配置図 (Mermaid)

## ライセンス

MIT
