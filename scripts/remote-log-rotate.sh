#!/bin/bash
# remote-log-rotate.sh
# infra01: 集約リモートログ /var/log/remote/<host>/YYYY-MM-DD.log の整理。
#   - 7日経過した .log を gzip 圧縮
#   - 30日経過した .gz を削除
# rsyslog が日付名で日次ファイルを作るので、ここでは圧縮と削除のみ。
# systemd timer (remote-log-rotate.timer) から日次実行する。
set -euo pipefail

BASE=/var/log/remote

# 7日より古い .log を gzip (当日ファイルは mtime が新しいので対象外)
find "$BASE" -type f -name '*.log'    -mtime +7  -exec gzip {} +

# 30日より古い .gz を削除
find "$BASE" -type f -name '*.log.gz' -mtime +30 -delete
