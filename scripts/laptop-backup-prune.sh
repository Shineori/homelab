#!/usr/bin/env bash
# Runs ON ShiNAS, weekly. The laptop's rest-server repo is append-only, so cleanup happens here,
# directly on the files, where the laptop has no say.
set -Eeuo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
export RESTIC_REPOSITORY=/volume2/backups/restic-laptop/shineoriserver
export RESTIC_PASSWORD_FILE=/root/.restic-laptop-password
export RESTIC_CACHE_DIR=/volume2/backups/.restic-cache
log() { echo "$(date '+%F %T') $*"; }

notify() {
  [ -r /root/.backup-webhook ] || return 0
  printf 'url = "%s"\n' "$(cat /root/.backup-webhook)" |
    curl -fsS -K - -H 'Content-Type: application/json' \
      -d "{\"content\":\"$1\"}" >/dev/null || true
}
trap 'notify "❌ **Laptop backup cleanup FAILED on ShiNAS** (line $LINENO). Check /var/log/laptop-backup-prune.log"' ERR

exec 9>/run/laptop-backup-prune.lock
if ! flock -n 9; then log "already running, exiting"; exit 0; fi
log "== prune start"
# Retention: 7 daily, 4 weekly, 6 monthly (same as the NAS's own backups)
restic forget --prune --group-by host,tags --keep-daily 7 --keep-weekly 4 --keep-monthly 6
# Verify the repository and re-read a sample of the actual data
restic check --read-data-subset=5%
log "== prune OK"
