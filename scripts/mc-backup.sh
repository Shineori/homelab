#!/usr/bin/env bash
# mc-backup.sh - daily Shineori SMP world backup
#  - Only backs up if the world actually changed since the last backup
#  - Keeps the 5 newest backups locally on ShineoriServer
#  - When a 6th appears, the oldest is copied to ShiNAS (kept forever),
#    and only deleted locally AFTER the copy succeeds
set -euo pipefail

# ================= CONFIG (check these!) =================
CONTAINER="shineori-mc"
DATA_DIR="/home/shineori/docker/minecraft/mc-data"   # host folder mounted to /data
WORLD_DIRS=("Brrr")                               # matches level-name; Fabric keeps Nether/End inside it
LOCAL_DIR="/home/shineori/backups/minecraft"
KEEP_LOCAL=5
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
# Any block placed/broken (once saved) changes it.
# Ignored: session.lock, and level.dat/level.dat_old (rewritten on EVERY save,
# even with nobody online, so they'd make every run look "changed").
# Also ignored: */entities/* (mob/entity files get re-saved with nobody online).
# Any real play session still trips it via players/, region/ terrain, data/, poi/.
# Everything ignored here is still included in the backup itself.
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

# 3) Rotation: anything beyond the newest 5 goes to ShiNAS
mapfile -t BACKUPS < <(find "$LOCAL_DIR" -maxdepth 1 -name 'world_*.tar.gz' | sort -r)

if (( ${#BACKUPS[@]} > KEEP_LOCAL )); then
  if ! $SSH_CMD "$NAS_HOST" "mkdir -p '$NAS_DIR'"; then
    log "ERROR: can't reach ShiNAS. Keeping extra backups locally, will retry next run."
    exit 1
  fi
  for OLD in "${BACKUPS[@]:KEEP_LOCAL}"; do
    NAME=$(basename "$OLD")
    LOCAL_SUM=$(sha256sum "$OLD" | cut -d' ' -f1)
    # Plain SSH pipe instead of rsync/scp: the NAS vendor swaps in its own rsync and
    # SFTP servers that remap or reject home-folder paths. A normal shell
    # command (cat) sees the real filesystem. Upload as .part, verify, rename.
    if $SSH_CMD "$NAS_HOST" "cat > '$NAS_DIR/$NAME.part'" < "$OLD" \
       && [[ "$($SSH_CMD "$NAS_HOST" "sha256sum '$NAS_DIR/$NAME.part'" | cut -d' ' -f1)" == "$LOCAL_SUM" ]] \
       && $SSH_CMD "$NAS_HOST" "mv '$NAS_DIR/$NAME.part' '$NAS_DIR/$NAME'"; then
      rm -f "$OLD"
      log "Archived to ShiNAS and verified: $NAME"
    else
      log "ERROR: transfer/verify failed for $NAME, keeping local copy."
    fi
  done
fi

log "===== Done ====="
