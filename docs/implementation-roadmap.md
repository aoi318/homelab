# HomeLab v1 実装ロードマップ

## 進め方

基本設計を一度に詳細化して実装するのではなく、依存関係が小さい単位で次を繰り返す。

1. 対象範囲の詳細設計を確定する
2. 構築し、動作を確認する
3. 実測した設定・検証結果・復旧手順を記録する
4. コミットして次の範囲へ進む

各範囲は、失敗しても家庭内LAN上のProxmox管理経路を維持したまま戻せることを原則とする。

## 実装順序

```text
Phase 0A: Proxmox基盤 ✅ 完了（2026-08-08）
    ・家庭内LAN管理経路確認
    ・vmbr1
    ・vmbr2
    ・VLAN-aware
    ・再起動試験

        ↓

Phase 1: OPNsense
    ・WAN
    ・LAN
    ・VLAN20 Infra
    ・VLAN30 Game
    ・Routing
    ・Firewall
    ・DNS/NTP

        ↓

Phase 2: infra01
    ・Debian
    ・固定IP
    ・SSH
    ・Docker
    ・外部疎通

        ↓

Phase 3: game01
    ・Debian
    ・固定IP
    ・admin / gamebot / backupuser
    ・SSH
    ・Docker
    ・永続データ領域

        ↓

Phase 4A: Game Server
    ・Compose
    ・ゲーム起動
    ・停止
    ・内部接続確認

        ↓

Phase 4B: Backup
    ・PVE → game01 SSH
    ・tar.zst
    ・1世代保持
    ・復元試験

        ↓

Phase 4C: 外部公開
    ・OPNsense NAT
    ・家庭用ルーター Port Forward
    ・外部接続試験
    ・不要ポート閉塞確認

        ↓

Phase 5: Discord Bot
    ・Proxmox API
    ・gamebot SSH
    ・!start
    ・!stop
    ・!status
    ・バックアップ連携
    ・異常通知

        ↓

Phase 0B: Proxmox管理強化
    ・管理ユーザー
    ・SSH公開鍵
    ・root SSH禁止
    ・PVE Firewall
    ・管理PC限定

        ↓

Phase 6: Lab
    ・vmbr1接続
    ・lab01
    ・完全分離確認
    ・OSPF検証開始

        ↓

Phase 7: 運用仕上げ
    ・再構築試験
    ・ゲームワールド復元試験
    ・OPNsense障害試験
    ・PVE再起動試験
    ・ドキュメント整理
    ・v1.0判定
```

## Phase 0A: Proxmox基盤（完了）

Phase 0Aでは、既存の管理PCから家庭内LAN経由でProxmoxへ接続する経路を変更しない。PVEの管理IP、デフォルトゲートウェイ、SSH認証方式、ホストファイアウォールはこの段階では変更しない。

ここで作成する`vmbr1`と`vmbr2`は物理NICを接続しない仮想ブリッジである。PVE管理ネットワークの`vmbr0`とは役割を分離する。

- `vmbr1`: lab01専用の完全分離ネットワーク
- `vmbr2`: OPNsense LANおよびVLAN 20/30を収容する、VLAN-awareなHomeLab内部ネットワーク

Phase 0Aの完了条件は次のとおり。

- [x] 作業前後で管理PCからPVEのWeb GUIおよびSSHへ接続できる
- [x] `vmbr1`と`vmbr2`が意図した設定で存在する
- [x] PVEを再起動しても、`vmbr0`の管理経路と新しいブリッジ設定が維持される
- [x] 設定内容とロールバック手順を記録する

## 補足

Phase 0Bは、PVE上で運用するVMと管理・復旧手順が安定してから実施する。root SSHを無効化する前に、管理用ユーザーのSSH公開鍵認証と、別セッションからのログインを必ず確認する。

外部公開はPhase 4Cまで行わず、Proxmox、OPNsense管理画面、infra01、lab01をインターネットへ公開しない。
