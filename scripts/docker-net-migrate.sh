#!/usr/bin/env bash
# Moves Docker's auto-assigned networks off a range that overlaps your home VLANs.
# Usage: OLD_PREFIX=<start of the range to leave> NEW_POOL=<cidr> bash docker-net-migrate.sh --dry-run
#        sudo OLD_PREFIX=<prefix> NEW_POOL=<cidr> bash docker-net-migrate.sh --apply
set -uo pipefail
MODE="${1:---dry-run}"
OLD_PREFIX="${OLD_PREFIX:?set OLD_PREFIX to the start of the range to leave}"
BASE="${NEW_POOL:?set NEW_POOL to a free range, one per host}"
HERE="$(cd "$(dirname "$0")" && pwd)"; STAMP="$(date +%Y%m%d-%H%M%S)"; CONF=/etc/docker/daemon.json
say(){ printf '\n== %s ==\n' "$*"; }

say "Reading current state"
mapfile -t RUNNING < <(docker ps --format '{{.Names}}')
declare -A DIRS FILES SVCS ENVF; EMPTY=(); AFFECTED=()
for n in $(docker network ls -q --filter driver=bridge); do
  sub=$(docker network inspect "$n" --format '{{range .IPAM.Config}}{{.Subnet}} {{end}}')
  case "$sub" in "$OLD_PREFIX"*) ;; *) continue;; esac
  name=$(docker network inspect "$n" --format '{{.Name}}')
  mapfile -t cs < <(docker network inspect "$n" --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' | sed '/^$/d')
  AFFECTED+=("$name")
  [ "${#cs[@]}" -eq 0 ] && { EMPTY+=("$name"); continue; }
  for c in "${cs[@]}"; do
    p=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project"}}')
    [ -z "$p" ] && { echo "ABORT: $c on $name isn't a compose container"; exit 1; }
    DIRS[$p]=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}')
    FILES[$p]=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}')
    ENVF[$p]=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project.environment_file"}}')
  done
done
for p in "${!DIRS[@]}"; do
  SVCS[$p]=$(docker ps --filter "label=com.docker.compose.project=$p" --format '{{.Label "com.docker.compose.service"}}' | sort -u | tr '\n' ' ')
done
compose(){ local p="$1"; shift; local a=(-p "$p" --project-directory "${DIRS[$p]}"); local f; IFS=, read -ra fs <<<"${FILES[$p]}"; for f in "${fs[@]}"; do a+=(-f "$f"); done; if [ -n "${ENVF[$p]}" ]; then IFS=, read -ra es <<<"${ENVF[$p]}"; for f in "${es[@]}"; do a+=(--env-file "$f"); done; fi; docker compose "${a[@]}" "$@"; }

echo "Host: $(hostname) | new pool: $BASE, one /24 per network"
echo "Running containers: ${#RUNNING[@]}"
echo "Networks to replace: ${AFFECTED[*]:-none}"
echo "Empty networks to remove: ${EMPTY[*]:-none}"
for p in "${!DIRS[@]}"; do echo "Stack $p -> ${DIRS[$p]} | services: ${SVCS[$p]}"; compose "$p" config -q >/dev/null 2>&1 && echo "   compose config OK" || echo "   compose config FAILED"; done
echo "Merged daemon.json:"
python3 - "$CONF" "$BASE" <<'PY'
import json,sys,os
p,b=sys.argv[1],sys.argv[2]
d=json.load(open(p)) if os.path.exists(p) else {}
d["default-address-pools"]=[{"base":b,"size":24}]
print(json.dumps(d,indent=2))
PY
if [ "$MODE" != "--apply" ]; then echo; echo "Dry run only. Nothing changed."; exit 0; fi
[ "$EUID" -eq 0 ] || { echo "Run --apply with sudo."; exit 1; }

say "1/6 Saving rollback info"
BK="$HERE/rollback-$STAMP"; mkdir -p "$BK"; [ -f "$CONF" ] && cp -a "$CONF" "$BK/daemon.json.bak"
printf '%s\n' "${RUNNING[@]}" > "$BK/running.txt"; docker network ls > "$BK/networks.txt"
for n in "${AFFECTED[@]}"; do docker network inspect "$n" > "$BK/net-$n.json" 2>/dev/null; done
python3 - "$CONF" "$BASE" "$BK/daemon.new" <<'PY'
import json,sys,os
p,b,o=sys.argv[1:4]
d=json.load(open(p)) if os.path.exists(p) else {}
d["default-address-pools"]=[{"base":b,"size":24}]
json.dump(d,open(o,"w"),indent=2)
PY
dockerd --validate --config-file "$BK/daemon.new" || { echo "ABORT: invalid config, nothing changed"; exit 1; }

say "2/6 Stopping all containers cleanly (up to 60s each)"
docker ps -q | xargs -r -n 8 -P 4 docker stop -t 60 >/dev/null

say "3/6 Removing old networks"
for n in "${AFFECTED[@]}"; do docker network rm "$n" >/dev/null && echo "removed $n" || echo "WARNING: could not remove $n"; done

say "4/6 Applying pool and restarting Docker"
install -m 644 "$BK/daemon.new" "$CONF"
if ! systemctl restart docker; then
  echo "Docker failed to restart. Restoring old config."; cp -a "$BK/daemon.json.bak" "$CONF"; systemctl restart docker; exit 1
fi
sleep 5

say "5/6 Recreating affected stacks, keeping their data"
FAIL=0
for p in "${!DIRS[@]}"; do echo "-- $p"; compose "$p" up -d --force-recreate --no-build --pull never ${SVCS[$p]} || { echo "FAILED: $p"; FAIL=1; }; done

say "6/6 Starting everything else that was running"
for pass in 1 2 3; do
  for c in "${RUNNING[@]}"; do [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ] || docker start "$c" >/dev/null 2>&1; done; sleep 5
done

say "Results"
MISSING=0; for c in "${RUNNING[@]}"; do [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ] || { echo "NOT RUNNING: $c"; MISSING=1; }; done
echo "Running now: $(docker ps -q | wc -l), before: ${#RUNNING[@]}"
echo "Docker routes still in that range:"; ip -4 route | grep -F "$OLD_PREFIX" | grep -E 'dev (br-|docker)' || echo "  none"
for ip in ${CHECK_IPS:-}; do echo "$ip -> $(ip route get "$ip" | head -1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')"; done
echo "Rollback files: $BK"
[ "$FAIL$MISSING" = "00" ] && echo "DONE: all good." || echo "FINISHED WITH PROBLEMS: check the output above."
