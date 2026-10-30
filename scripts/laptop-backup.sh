#!/usr/bin/env bash
# Nightly encrypted backups of ShineoriServer's apps -> append-only restic rest-server on ShiNAS.
# The laptop can ADD snapshots but can't delete or change them; ShiNAS prunes on its own schedule.
set -Eeuo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
export RESTIC_REPOSITORY_FILE=/root/.restic-repo        # rest:http://user:pass@nas:8500/user/  (chmod 600)
export RESTIC_PASSWORD_FILE=/root/.restic-password      # encryption password (chmod 600, also in Vaultwarden)
DOCKER=/home/shineori/docker
VOL=/var/lib/docker/volumes
STAGE=/var/backups/homelab-staging
PAUSE=(uptime-kuma karakeep-web-1 paperless)            # SQLite apps: stopped for a few seconds = consistent copy
log() { echo "$(date '+%F %T') $*"; }

notify() {  # Discord alert; webhook read from a root-only file and passed via stdin (never in argv)
  [ -r /root/.backup-webhook ] || return 0
  printf 'url = "%s"\n' "$(cat /root/.backup-webhook)" |
    curl -fsS -K - -H 'Content-Type: application/json' \
      -d "{\"content\":\"$1\"}" >/dev/null || true
}
restart_apps() { docker start "${PAUSE[@]}" >/dev/null 2>&1 || true; }
trap 'notify "❌ **ShineoriServer backup FAILED** (line $LINENO). Check /var/log/laptop-backup.log"' ERR
trap 'restart_apps; rm -rf "$STAGE"' EXIT                 # apps ALWAYS come back, even after a failure

exec 9>/run/laptop-backup.lock
if ! flock -n 9; then log "already running, exiting"; exit 0; fi
log "== backup start"
rm -rf "$STAGE"; mkdir -p "$STAGE"; chmod 700 "$STAGE"

# 1) Dawarich: consistent PostgreSQL dump while it keeps running, then sanity-check it
docker exec dawarich_db pg_dump -U postgres -Fc dawarich_development > "$STAGE/dawarich.dump"
docker exec -i dawarich_db pg_restore --list < "$STAGE/dawarich.dump" > /dev/null
log "dawarich dump: $(du -h "$STAGE/dawarich.dump" | cut -f1), readable"

# 2) addy.io: consistent MariaDB dump while it keeps running, then sanity-check it
docker exec addy-db sh -c 'exec mariadb-dump --single-transaction --routines -u anonaddy -p"$MARIADB_PASSWORD" anonaddy' > "$STAGE/addy.sql"
tail -n 1 "$STAGE/addy.sql" | grep -q 'Dump completed'
log "addy dump: $(du -h "$STAGE/addy.sql" | cut -f1), complete"

# 3) Pause the SQLite apps, back everything up, start them again (EXIT trap guarantees the restart)
docker stop "${PAUSE[@]}" > /dev/null
log "paused: ${PAUSE[*]}"
restic backup --host shineoriserver --tag apps \
  "$STAGE" \
  "$DOCKER/dawarich" "$VOL/dawarich_dawarich_storage/_data" "$VOL/dawarich_dawarich_watched/_data" \
  "$VOL/dawarich_dawarich_public/_data" \
  "$DOCKER/uptime-kuma" \
  "$DOCKER/karakeep" "$VOL/karakeep_data/_data" \
  "$DOCKER/paperless" \
  "$DOCKER/addy" --exclude "$DOCKER/addy/db" --exclude "$DOCKER/addy/redis" \
  "$DOCKER/sites"
restart_apps
log "restarted: ${PAUSE[*]}"

log "== backup OK"
