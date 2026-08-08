# HomeLab v1 実装ロードマップ

## 進め方

基本設計を一度に詳細化して実装するのではなく、依存関係が小さい単位で次を繰り返す。

1. 対象範囲の詳細設計を確定する
2. 構築し、動作を確認する
3. 実測した設定・検証結果・復旧手順を記録する
4. コミットして次の範囲へ進む

初期構成では、PVEの管理経路とLabの完全分離を維持する。通常VMは家庭内LAN上の`vmbr0`へ接続し、PVEホストをルーターとして使わない。

## 実装順序

```text
Phase 0A: PVE基盤 ✅ 完了
    ・家庭内LAN管理経路確認
    ・vmbr1（Lab分離）
    ・再起動試験

        ↓

Phase 0A.1: ブリッジ構成の簡素化 ✅ 完了（2026-08-09）
    ・vmbr0を通常VM用として確認
    ・vmbr1をLab専用として確認
    ・不要なvmbr2を削除
    ・PVEにLab向けIP・ルーティングを追加しないことを確認
    ・再起動試験

        ↓

Phase 1: infra01 🟡 構築済み・DHCP予約待ち
    ・Debian
    ・固定IP
    ・SSH
    ・Docker
    ・外部疎通

        ↓

Phase 2: game01
    ・Debian
    ・固定IP
    ・admin / gamebot / backupuser
    ・SSH
    ・Docker
    ・永続データ領域

        ↓

Phase 3: Game Server
    ・Compose
    ・ゲーム起動
    ・停止
    ・内部接続確認

        ↓

Phase 4: Backup
    ・PVE → game01 SSHの管理経路設計
    ・tar.zst
    ・1世代保持
    ・復元試験

        ↓

Phase 4C: 外部公開
    ・家庭用ルーター Port Forward
    ・game01のホストFirewall
    ・外部接続試験
    ・不要ポート閉塞確認

        ↓

Phase 5: Discord Bot
    ・Proxmox API
    ・game01の専用操作経路
    ・!start
    ・!stop
    ・!status
    ・バックアップ連携
    ・異常通知

        ↓

Phase 0B: PVE管理強化
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
    ・ネットワーク境界障害試験
    ・PVE再起動試験
    ・ドキュメント整理
    ・v1.0判定
```

## OPNsenseの扱い

OPNsenseはSHOULD機能であり、初期構成の前提としない。通常VMは家庭内LANへ直接接続し、外部公開は家庭用ルーターとgame01のホストFirewallで制御する。

OPNsenseを将来採用する場合は、ルーティング、Firewall、NAT、集中DNS/NTPを担わせる。初期構成ではPVEホストへルーター機能を追加しない。

## 次に着手する範囲: Phase 0A.1

通常VMが`vmbr0`を使用し、lab01だけが`vmbr1`を使用する構成へ整えた。`vmbr2`は削除済みである。PVEに`vmbr1`向けのIPv4、デフォルトゲートウェイ、ルーティングを設定していない。

この範囲ではOPNsense VMを利用しない。PVEの家庭内LAN上の管理IP、`vmbr0`、SSH認証方式、ホストファイアウォールは変更しない。
