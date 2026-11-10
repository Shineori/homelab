#!/usr/bin/env bash
# Backrest command hooks for ShineoriServer. Backrest runs these as root (native install, --root).
# Replaces the prep/cleanup steps of /usr/local/bin/laptop-backup.sh. The backup paths and excludes
# now live in the Backrest plan "apps"; the repo is the append-only rest-server on ShiNAS.
#
# Usage:
#   laptop-hooks.sh pre   (plan apps, CONDITION_SNAPSHOT_START, ON_ERROR_FATAL)
#   laptop-hooks.sh post  (plan apps, CONDITION_SNAPSHOT_END,   ON_ERROR_IGNORE)
set -Eeuo pipefail
# Installed at /usr/local/lib/backrest-hooks/laptop-hooks.sh (root, chmod 700). See docs/infrastructure/backrest.md
export PATH=/usr/local/bin:/usr/bin:/bin
STAGE=/var/backups/homelab-staging
PAUSE=(uptime-kuma karakeep-web-1 paperless)   # SQLite apps: stopped for the snapshot = consistent copy
log() { echo "$(date '+%F %T') [laptop-hooks] $*"; }
restart_apps() { docker start "${PAUSE[@]}" >/dev/null 2>&1 || true; }

pre() {
  # If anything below fails, the apps come straight back (Backrest also runs "post" on SNAPSHOT_END).
  trap 'restart_apps' ERR
  rm -rf "$STAGE"; mkdir -p "$STAGE"; chmod 700 "$STAGE"

  # Dawarich: consistent PostgreSQL dump while it keeps running, then sanity-check it
  docker exec dawarich_db pg_dump -U postgres -Fc dawarich_development > "$STAGE/dawarich.dump"
  docker exec -i dawarich_db pg_restore --list < "$STAGE/dawarich.dump" > /dev/null
  log "dawarich dump: $(du -h "$STAGE/dawarich.dump" | cut -f1), readable"

  # addy.io: consistent MariaDB dump while it keeps running, then sanity-check it
  docker exec addy-db sh -c 'exec mariadb-dump --single-transaction --routines -u anonaddy -p"$MARIADB_PASSWORD" anonaddy' > "$STAGE/addy.sql"
  tail -n 1 "$STAGE/addy.sql" | grep -q 'Dump completed'
  log "addy dump: $(du -h "$STAGE/addy.sql" | cut -f1), complete"

  # Pause the SQLite apps last, so they're down only while restic reads
  docker stop "${PAUSE[@]}" > /dev/null
  log "paused: ${PAUSE[*]}"
}

post() {
  restart_apps
  log "restarted: ${PAUSE[*]}"
  rm -rf "$STAGE"
}

case "${1:-}" in
  pre)  pre ;;
  post) post ;;
  *) echo "usage: $0 pre|post" >&2; exit 2 ;;
esac
