#!/usr/bin/env bash
# mc-backup.sh - daily Shineori SMP world backup
#  - Only creates a backup if the world actually changed since the last one
#  - ShineoriServer keeps just the newest backup
#  - Every backup is copied to ShiNAS (sha256-verified); ShiNAS keeps the newest 2
#    (= same as ShineoriServer + one safe rollback)
#  - Old copies are only deleted AFTER the newer ones are verified on ShiNAS
set -euo pipefail

# ================= CONFIG (check these!) =================
CONTAINER="shineori-mc"
DATA_DIR="/home/shineori/docker/minecraft/mc-data"   # host folder mounted to /data
WORLD_DIRS=("Brrr")                               # matches level-name; Fabric keeps Nether/End inside it
LOCAL_DIR="/home/shineori/backups/minecraft"
KEEP_LOCAL=1
KEEP_NAS=2
NAS_HOST="shineori@<nas-lan-ip>"
NAS_DIR="/home/shineori/backups/minecraft"          # full path, since ~ won't expand inside the remote command
SSH_KEY="/root/.ssh/nas_backup"
# =========================================================

STATE_FILE="$LOCAL_DIR/.last_fingerprint"
LOG_FILE="$LOCAL_DIR/backup.log"
mkdir -p "$LOCAL_DIR"
exec >>"$LOG_FILE" 2>&1

# Prevent two runs overlapping
exec 9>"$LOCAL_DIR/.lock"
flock -n 9 || { echo "Another backup is running, exiting."; exit 0; }

log() { echo "[$(date '+%F %T')] $*"; }
SSH_CMD="ssh -i $SSH_KEY -o BatchMode=yes -o ConnectTimeout=10"
rcon() { docker exec "$CONTAINER" rcon-cli "$@" >/dev/null 2>&1 || log "WARN: rcon '$*' failed"; }

# Fingerprint = every file's path + size + modified time, hashed.
# Ignored: session.lock, level.dat/level.dat_old and */entities/* (re-saved even
# with nobody online). Everything ignored here is still included in the backup.
fingerprint() {
  (cd "$DATA_DIR" && find "${WORLD_DIRS[@]}" -type f ! -name session.lock ! -name 'level.dat*' \
     ! -path '*/entities/*' \
     -printf '%p %s %T@\n' | sort | sha256sum | cut -d' ' -f1)
}

log "===== Backup run started ====="

# 1) If the server is running, flush everything to disk and pause autosave
RUNNING=false
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  RUNNING=true
  rcon save-off
  trap 'rcon save-on' EXIT          # autosave ALWAYS gets turned back on
  rcon save-all flush
  sleep 5
fi

# 2) Change detection
NEW_FP=$(fingerprint)
OLD_FP=$(cat "$STATE_FILE" 2>/dev/null || true)

if [[ "$NEW_FP" == "$OLD_FP" ]]; then
  log "No changes since last backup, skipping."
else
  STAMP=$(date '+%Y-%m-%d_%H%M')
  FILE="$LOCAL_DIR/world_$STAMP.tar.gz"
  # tar exit code 1 = "file changed while reading" (harmless warning)
  tar -czf "$FILE.part" -C "$DATA_DIR" --exclude='session.lock' "${WORLD_DIRS[@]}" || [[ $? -eq 1 ]]
  mv "$FILE.part" "$FILE"
  echo "$NEW_FP" > "$STATE_FILE"
  log "Created $(basename "$FILE") ($(du -h "$FILE" | cut -f1))"
fi

# Turn autosave back on now (don't keep it off during the NAS transfer)
if $RUNNING; then rcon save-on; trap - EXIT; fi

# 3) Make sure the newest KEEP_NAS local backups are on ShiNAS (catches up after a missed run)
mapfile -t BACKUPS < <(find "$LOCAL_DIR" -maxdepth 1 -name 'world_*.tar.gz' | sort -r)
(( ${#BACKUPS[@]} > 0 )) || { log "No local backups yet."; log "===== Done ====="; exit 0; }

if ! $SSH_CMD "$NAS_HOST" "mkdir -p '$NAS_DIR'"; then
  log "ERROR: can't reach ShiNAS. Nothing deleted anywhere, will retry next run."
  exit 1
fi

SYNC_OK=true
for F in "${BACKUPS[@]:0:KEEP_NAS}"; do
  NAME=$(basename "$F")
  # Only fully verified uploads get their final name, so "exists" = "verified"
  if $SSH_CMD "$NAS_HOST" "test -f '$NAS_DIR/$NAME'"; then continue; fi
  LOCAL_SUM=$(sha256sum "$F" | cut -d' ' -f1)
  # Plain SSH pipe instead of rsync/scp: the NAS vendor swaps in its own rsync and
  # SFTP servers that remap or reject home-folder paths. Upload as .part, verify, rename.
  if $SSH_CMD "$NAS_HOST" "cat > '$NAS_DIR/$NAME.part'" < "$F" \
     && [[ "$($SSH_CMD "$NAS_HOST" "sha256sum '$NAS_DIR/$NAME.part'" | cut -d' ' -f1)" == "$LOCAL_SUM" ]] \
     && $SSH_CMD "$NAS_HOST" "mv '$NAS_DIR/$NAME.part' '$NAS_DIR/$NAME'"; then
    log "Copied to ShiNAS and verified: $NAME"
  else
    log "ERROR: transfer/verify failed for $NAME"
    SYNC_OK=false
  fi
done

if ! $SYNC_OK; then
  log "Skipping cleanup so nothing is lost; will retry next run."
  exit 1
fi

# 4) Cleanup, only after everything above is safely on ShiNAS
#    ShiNAS: keep the newest KEEP_NAS world_*.tar.gz (+ remove stale .part leftovers)
$SSH_CMD "$NAS_HOST" "cd '$NAS_DIR' && rm -f -- world_*.tar.gz.part && ls -1 world_*.tar.gz 2>/dev/null | sort -r | tail -n +$((KEEP_NAS + 1)) | xargs -r rm -f --" \
  && log "ShiNAS now holds: $($SSH_CMD "$NAS_HOST" "cd '$NAS_DIR' && ls -1 world_*.tar.gz | sort -r | tr '\n' ' '")"

#    ShineoriServer: keep the newest KEEP_LOCAL
for OLD in "${BACKUPS[@]:KEEP_LOCAL}"; do
  rm -f -- "$OLD"
  log "Removed local copy: $(basename "$OLD")"
done

log "===== Done ====="
