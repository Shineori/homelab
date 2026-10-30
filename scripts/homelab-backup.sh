#!/usr/bin/env bash
# Nightly encrypted backups: Vaultwarden + Immich + Authentik -> restic repo on the second disk.
set -Eeuo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
export RESTIC_REPOSITORY=/volume2/backups/restic
export RESTIC_PASSWORD_FILE=/root/.restic-password
export RESTIC_CACHE_DIR=/volume2/backups/.restic-cache   # keep cache off the small system disk
DOCKER=/home/shineori/docker
STAGE=/volume2/backups/staging/vaultwarden
AK_STAGE=/volume2/backups/staging/authentik
VW="$DOCKER/vaultwarden/vw-data"
AK="$DOCKER/authentik"
AK_DB=authentik-postgresql-1                            # Authentik's PostgreSQL container
log() { echo "$(date '+%F %T') $*"; }

notify() {  # Discord alert; webhook read from a root-only file and passed via stdin (never in argv)
  [ -r /root/.backup-webhook ] || return 0
  printf 'url = "%s"\n' "$(cat /root/.backup-webhook)" |
    curl -fsS -K - -H 'Content-Type: application/json' \
      -d "{\"content\":\"$1\"}" >/dev/null || true
}
trap 'notify "❌ **ShiNAS backup FAILED** (line $LINENO). Check /var/log/homelab-backup.log"; rm -rf "$STAGE" "$AK_STAGE"' ERR

exec 9>/run/homelab-backup.lock
if ! flock -n 9; then log "already running, exiting"; exit 0; fi
log "== backup start"

# 1) Vaultwarden: consistent SQLite snapshot (safe while the app is writing), then integrity check
rm -rf "$STAGE"
mkdir -p "$STAGE"
python3 - "$VW/db.sqlite3" "$STAGE/db.sqlite3" <<'PY'
import sqlite3, sys
src = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
ok = dst.execute("PRAGMA integrity_check").fetchone()[0]
dst.close(); src.close()
sys.exit(0 if ok == "ok" else f"integrity_check failed: {ok}")
PY
log "vaultwarden db snapshot: integrity ok"
cp -a "$VW"/rsa_key* "$STAGE/"
for d in attachments sends; do
  if [ -d "$VW/$d" ]; then cp -a "$VW/$d" "$STAGE/"; fi
done
if [ -f "$VW/config.json" ]; then cp -a "$VW/config.json" "$STAGE/"; fi

# 2) Authentik: consistent PostgreSQL dump while it keeps running, then prove it's readable.
#    Plus the files a rebuild needs: .env (secret key + DB password), compose.yml, data, certs, custom-templates.
rm -rf "$AK_STAGE"
mkdir -p "$AK_STAGE"
chmod 700 "$AK_STAGE"
docker exec "$AK_DB" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$AK_STAGE/authentik.dump"
docker exec -i "$AK_DB" pg_restore --list < "$AK_STAGE/authentik.dump" > /dev/null
log "authentik dump: $(du -h "$AK_STAGE/authentik.dump" | cut -f1), readable"
cp -a "$AK/.env" "$AK/compose.yml" "$AK/data" "$AK/certs" "$AK/custom-templates" "$AK_STAGE/"

# 3) Back up
restic backup --host shinas --tag vaultwarden "$STAGE"
restic backup --host shinas --tag immich \
  --exclude "$DOCKER/immich/library/thumbs" \
  --exclude "$DOCKER/immich/library/encoded-video" \
  "$DOCKER/immich/library"
restic backup --host shinas --tag authentik "$AK_STAGE"
rm -rf "$STAGE" "$AK_STAGE"

# 4) Retention: 7 daily, 4 weekly, 12 monthly = 1 year (per tag, so each app keeps its own history)
restic forget --prune --group-by host,tags --keep-daily 7 --keep-weekly 4 --keep-monthly 12

# 5) Verify the repository and re-read a sample of the actual data
restic check --read-data-subset=5%
log "== backup OK"
