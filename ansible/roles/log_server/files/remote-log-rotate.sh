#!/bin/bash
# infra01: /var/log/remote/<host>/YYYY-MM-DD.log の整理 (7d gzip / 30d delete)
set -euo pipefail
BASE=/var/log/remote
find "$BASE" -type f -name '*.log'    -mtime +7  -exec gzip {} +
find "$BASE" -type f -name '*.log.gz' -mtime +30 -delete
