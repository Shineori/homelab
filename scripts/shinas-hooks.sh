#!/usr/bin/env bash
# Backrest command hooks for ShiNAS. Backrest runs these as root (native install, --root).
# Replaces the prep steps of /usr/local/bin/homelab-backup.sh and the forget step of
# /usr/local/bin/laptop-backup-prune.sh, so Backrest owns all scheduling.
#
# Usage:
#   shinas-hooks.sh pre  vaultwarden|authentik|website   (CONDITION_SNAPSHOT_START, ON_ERROR_FATAL)
#   shinas-hooks.sh post vaultwarden|authentik|website   (CONDITION_SNAPSHOT_END,   ON_ERROR_IGNORE)
#   shinas-hooks.sh laptop-forget    (shineoriserver repo, CONDITION_PRUNE_START, ON_ERROR_FATAL)
#   shinas-hooks.sh legacy-forget    (shinas repo, CONDITION_PRUNE_START, ON_ERROR_FATAL)
set -Eeuo pipefail
# Installed at /usr/local/lib/backrest-hooks/shinas-hooks.sh (root, chmod 700). See docs/infrastructure/backrest.md
export PATH=/usr/local/bin:/usr/bin:/bin
DOCKER=/home/shineori/docker
STAGING=/volume2/backups/staging
CACHE=/volume2/backups/.restic-cache          # keep restic cache off the small system disk
KEEP=(--keep-daily 7 --keep-weekly 4 --keep-monthly 12)   # 1 year, same as the old scripts
log() { echo "$(date '+%F %T') [shinas-hooks] $*"; }

# Consistent copy of a live SQLite DB (safe while the app writes), then integrity check.
sqlite_snapshot() {
  python3 - "$1" "$2" <<'PY'
import sqlite3, sys
src = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
ok = dst.execute("PRAGMA integrity_check").fetchone()[0]
dst.close(); src.close()
sys.exit(0 if ok == "ok" else f"integrity_check failed: {ok}")
PY
}

fresh_stage() { rm -rf "$1"; mkdir -p "$1"; chmod 700 "$1"; }

pre_vaultwarden() {
  local VW="$DOCKER/vaultwarden/vw-data" S="$STAGING/vaultwarden"
  fresh_stage "$S"
  sqlite_snapshot "$VW/db.sqlite3" "$S/db.sqlite3"
  log "vaultwarden db snapshot: integrity ok"
  cp -a "$VW"/rsa_key* "$S/"
  for d in attachments sends; do [ -d "$VW/$d" ] && cp -a "$VW/$d" "$S/"; done
  [ -f "$VW/config.json" ] && cp -a "$VW/config.json" "$S/"
  return 0
}

pre_authentik() {
  local AK="$DOCKER/authentik" S="$STAGING/authentik" DB=authentik-postgresql-1
  fresh_stage "$S"
  docker exec "$DB" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$S/authentik.dump"
  docker exec -i "$DB" pg_restore --list < "$S/authentik.dump" > /dev/null
  log "authentik dump: $(du -h "$S/authentik.dump" | cut -f1), readable"
  cp -a "$AK/.env" "$AK/compose.yml" "$AK/data" "$AK/certs" "$AK/custom-templates" "$S/"
}

pre_website() {
  # The real site and plan names are redacted in this public copy.
  local DS="$DOCKER/sites/website" S="$STAGING/website"
  fresh_stage "$S"
  sqlite_snapshot "$DS/counter/data/visits.db" "$S/visits.db"
  log "website counter db snapshot: integrity ok"
  cp -a "$DS/docker-compose.yml" "$DS/nginx.conf" "$DS/counter/counter.py" "$DS/public" "$S/"
}

# The laptop's rest-server is append-only, so its retention runs here, on the files directly.
# --group-by host merges the old script snapshots (tag "apps") with Backrest's (tag "plan:..."),
# so the old ones age out naturally. Backrest's own prune runs right after this hook.
laptop_forget() {
  RESTIC_REPOSITORY=/volume2/backups/restic-laptop/shineoriserver \
  RESTIC_PASSWORD_FILE=/root/.restic-laptop-password RESTIC_CACHE_DIR="$CACHE" \
    restic forget --group-by host "${KEEP[@]}"
}

# Snapshots made by the old homelab-backup.sh carry plain tags (vaultwarden, immich, ...).
# Backrest's per-plan retention only sees its own "plan:" tags, so expire the old ones after a year.
legacy_forget() {
  RESTIC_REPOSITORY=/volume2/backups/restic \
  RESTIC_PASSWORD_FILE=/root/.restic-password RESTIC_CACHE_DIR="$CACHE" \
    restic forget --group-by host,tags --tag vaultwarden --tag immich --tag authentik --tag website \
      --keep-within 1y
}

case "${1:-} ${2:-}" in
  "pre vaultwarden")  pre_vaultwarden ;;
  "pre authentik")    pre_authentik ;;
  "pre website")  pre_website ;;
  "post vaultwarden"|"post authentik"|"post website") rm -rf "${STAGING:?}/$2"; log "cleaned $2 staging" ;;
  "laptop-forget ")   laptop_forget ;;
  "legacy-forget ")   legacy_forget ;;
  *) echo "usage: $0 pre|post vaultwarden|authentik|website | laptop-forget | legacy-forget" >&2; exit 2 ;;
esac
