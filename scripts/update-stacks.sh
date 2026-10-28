#!/usr/bin/env bash
# Backup-then-update for ShineoriServer stacks. Run with: sudo bash ~/docker/update-stacks.sh [stack ...]
# Each stack: pull new images -> stop -> back up stack folder + named volumes -> up -d -> show status.
# Stacks that aren't running are skipped (nothing gets started that you had off).
set -u
DOCKER_DIR=/home/shineori/docker
B=/home/shineori/backups/pre-update-$(date +%F_%H%M)
DEFAULT="uptime-kuma dawarich karakeep ollama-stack anisette omnisette minecraft"
STACKS="${*:-$DEFAULT}"
mkdir -p "$B"; SUMMARY=()

for st in $STACKS; do
  echo; echo "================ $st ================"
  cd "$DOCKER_DIR/$st" || { SUMMARY+=("$st: ? folder missing"); continue; }
  if [ -z "$(docker compose ps -q 2>/dev/null)" ]; then SUMMARY+=("$st: ?? not running, skipped"); continue; fi
  proj=$(docker compose config --format json | python3 -c 'import json,sys;print(json.load(sys.stdin)["name"])')

  echo "-- pulling (stack keeps running meanwhile)"
  docker compose pull || { SUMMARY+=("$st: ? pull failed, left untouched"); continue; }

  echo "-- stopping + backing up to $B/$st"
  mkdir -p "$B/$st"
  docker compose stop
  tar czf "$B/$st/stack-folder.tgz" -C "$DOCKER_DIR" "$st" || { SUMMARY+=("$st: ? folder backup failed, restarting old version"); docker compose start; continue; }
  for vol in $(docker volume ls -q --filter "label=com.docker.compose.project=$proj"); do
    docker run --rm -v "$vol":/v:ro -v "$B/$st":/b alpine tar czf "/b/volume-$vol.tgz" -C /v . \
      || { SUMMARY+=("$st: ? volume $vol backup failed, restarting old version"); docker compose start; continue 2; }
  done

  echo "-- starting new version"
  docker compose up -d --remove-orphans
  sleep 25
  docker compose ps --format 'table {{.Name}}\t{{.Image}}\t{{.Status}}'
  if docker compose ps --format '{{.Status}}' | grep -qiE 'restarting|exited|unhealthy'; then
    SUMMARY+=("$st: ?? up, but something looks unhealthy, check logs")
  else SUMMARY+=("$st: ? updated ($(du -sh "$B/$st" | cut -f1) backup)"); fi
done

echo; echo "================ SUMMARY ================"; printf '%s\n' "${SUMMARY[@]}"
echo "Backups: $B"
docker image prune -f >/dev/null && echo "(old dangling images pruned)"
