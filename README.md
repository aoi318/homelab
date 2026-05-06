# homelab

学習目的の個人homelabプロジェクト。
Proxmox上のVMから始め、Kubernetes化、フルスタックの監視基盤、GitOpsまでを段階的に構築する。

## 状態

Phase 0: 基盤準備中

## 技術スタック(構築予定)

- **ハイパーバイザ**: Proxmox VE 9
- **プロビジョニング**: Ansible
- **アプリケーション**: Go (URL短縮API)
- **コンテナ**: Docker
- **オーケストレーション**: k3s + Helm + Argo CD
- **オブザーバビリティ**: Prometheus + Grafana + Loki + Tempo
- **CI/CD**: GitHub Actions + ghcr.io

## 構成

(構成図はPhase 0完了時に追加予定)

## ドキュメント

- `docs/architecture.md`: 全体構成と設計判断
- `docs/diagrams/`: Mermaid形式の構成図

## ライセンス

MIT