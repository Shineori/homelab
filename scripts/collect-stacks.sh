#!/usr/bin/env bash
# collect-stacks.sh: copy compose files from a server into this repo, REDACTED for a public repo.
# Run from the repo root, once per host:
#   ./scripts/collect-stacks.sh nas    ~/docker      (ShiNAS)
#   ./scripts/collect-stacks.sh laptop ~/docker      (ShineoriServer)
#   - copies the compose file of each stack that lives on THAT host (see MAP)
#   - auto-redacts secret-looking values, tunnel tokens, webhooks, emails, LAN IPs
#   - turns .env into .env.example with ALL values blanked
#   - never copies data folders
# Auto-redaction is a safety net, NOT a guarantee. Always review + run gitleaks.
set -euo pipefail

HOST="${1:-}"
SRC="${2:-$HOME/docker}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
case "$HOST" in
  nas|laptop) ;;
  *) echo "usage: $0 <nas|laptop> [docker-folder]" >&2; exit 1 ;;
esac

# host:repo-folder:server-folder   (edit when a stack moves, or if folder names differ)
# A stack is only collected from the host it lives on, so old rollback copies
# left behind on another machine never overwrite the real one.
MAP=(
  # ShiNAS: storage-heavy apps and identity
  nas:authentik:authentik  nas:vaultwarden:vaultwarden  nas:cloudflared:cloudflared
  nas:jellyfin:jellyfin  nas:immich:immich
  nas:arr-stack:arr-stack  nas:qbittorrent-mam:qbittorrent
  nas:audiobookshelf:AudioBookShelf  nas:flowcase:Flowcase
  nas:terraria:terraria  nas:resume-site:resume-site  nas:diun:diun  nas:restic-server:restic-server
  # ShineoriServer: RAM-hungry apps with small data (moved off the NAS)
  laptop:immich-ml:immich-ml  laptop:uptime-kuma:uptime-kuma
  laptop:dawarich:dawarich  laptop:karakeep:karakeep  laptop:ghiro:ghiro-docker
  laptop:minecraft:minecraft  laptop:ollama-stack:ollama-stack
  laptop:omada-controller:omada  laptop:paperless:paperless
)

# Your own domain(s) as one regex: every host under them becomes <redacted-domain>.
# The list is kept OUT of this public repo, in a git-ignored file next to this script:
#   echo 'yourdomain\.(me|com)' > scripts/private-domains.local
DOMAINS_FILE="$REPO/scripts/private-domains.local"
PRIVATE_DOMAINS="$(tr -d '[:space:]' 2>/dev/null < "$DOMAINS_FILE" || true)"
if [ -z "$PRIVATE_DOMAINS" ]; then
  echo "ERROR: $DOMAINS_FILE is missing or empty. Refusing to run without domain redaction." >&2
  exit 1
fi

SECRET_KEYS='[A-Za-z0-9_]*(PASS|PASSWORD|PASSWD|TOKEN|SECRET|PRIVATE|API_?KEY|AUTH_KEY|WEBHOOK|CLIENT_ID|SMTP_USER|LICENSE|SALT|ENCRYPTION|ADMIN_USER|ADMIN_EMAIL|ADMIN_NAME)[A-Za-z0-9_]*'

redact() {
  sed -E \
    -e "s/^([[:space:]]*-?[[:space:]]*\"?)(${SECRET_KEYS})([[:space:]]*[:=][[:space:]]*).+/\1\2\4<redacted>/I" \
    -e 's/(--token[ =])[^ "]+/\1<redacted>/g' \
    -e 's#https://(discord(app)?\.com)/api/webhooks/[^ "]+#https://\1/api/webhooks/<redacted>#g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<redacted-email>/g' \
    -e 's/192\.168\.[0-9]+\.[0-9]+/<LAN_IP>/g' \
    -E -e "s/([A-Za-z0-9-]+\.)*(${PRIVATE_DOMAINS})/<redacted-domain>/g"
}

for entry in "${MAP[@]}"; do
  [ "${entry%%:*}" = "$HOST" ] || continue
  pair="${entry#*:}"
  dest="${pair%%:*}"; src="$SRC/${pair##*:}"
  [ -d "$src" ] || { echo "skip  $dest  (no $src on this machine)"; continue; }
  mkdir -p "$REPO/stacks/$dest"
  found=0
  for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    if [ -f "$src/$f" ]; then
      redact < "$src/$f" > "$REPO/stacks/$dest/docker-compose.yml"; found=1; break
    fi
  done
  # Flowcase is an upstream clone: our real config is the override files
  if [ "$dest" = flowcase ]; then
    for f in docker-compose.nas.yml docker-compose-vpn.yml docker-compose-authentik.yml docker-compose.override.yml; do
      [ -f "$src/$f" ] && redact < "$src/$f" > "$REPO/stacks/$dest/$f"
    done
    rm -f "$REPO/stacks/$dest/docker-compose.yml"   # stock upstream file, not ours
    found=1
  fi
  # every env file (.env, tunnel.env, vpn.env) -> *.example with values blanked
  for e in "$src"/.env "$src"/*.env; do
    [ -f "$e" ] || continue
    name="$(basename "$e")"
    sed -E 's/^([[:space:]]*[A-Za-z_][A-Za-z0-9_]*)=.*/\1=/' "$e" > "$REPO/stacks/$dest/${name}.example"
  done
  [ $found = 1 ] && echo "ok    $dest  <-  $src" || echo "WARN  $dest  (folder exists but no compose file)"
done

echo
echo "Next:  1) git diff            (read every line)"
echo "       2) grep -rniE 'password|token|secret|key|@' stacks/"
echo "       3) gitleaks detect --source . -v"
