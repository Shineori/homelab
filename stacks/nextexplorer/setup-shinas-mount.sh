#!/usr/bin/env bash
# Mounts the ShiNAS SMB shares on ShineoriServer under /mnt/shinas for NextExplorer.
# Safe to re-run: it rewrites only its own marked block in /etc/fstab.
set -euo pipefail

NAS=<NAS_IP>
ROOT=/mnt/shinas
CRED=/etc/shinas-smb.cred
OPTS="credentials=$CRED,vers=3,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,nosuid,nodev,_netdev,nofail"
# local-name:share-name
SHARES="home:personal_folder hardcoressd:HardcoreSSD share:putAnyFilesYouWantToShareHere isos:ISOs docker:docker data:data"
BEGIN="# BEGIN shinas-nextexplorer"
END="# END shinas-nextexplorer"

[ "$(id -u)" = 0 ] || { echo "Run this with sudo."; exit 1; }

command -v mount.cifs >/dev/null || { apt-get update -qq; apt-get install -y -qq cifs-utils; }

if [ ! -s "$CRED" ]; then
  read -rsp "ShiNAS password for shineori (hidden as you type): " PW; echo
  ( umask 077; printf 'username=shineori\npassword=%s\n' "$PW" > "$CRED" )
  unset PW
fi
chown root:root "$CRED"; chmod 600 "$CRED"

# Try one share first, so a wrong password can't rack up repeated failed logins.
TEST=$(mktemp -d)
if ! mount -t cifs "//$NAS/HardcoreSSD" "$TEST" -o "credentials=$CRED,vers=3,ro"; then
  rmdir "$TEST"; rm -f "$CRED"
  echo "Login test failed and nothing was changed. Run this again to re-enter the password."
  exit 1
fi
umount "$TEST"; rmdir "$TEST"
echo "Login OK."

GOOD=""; SKIPPED=""
mkdir -p "$ROOT"
for pair in $SHARES; do
  name=${pair%%:*}; share=${pair##*:}; mp="$ROOT/$name"
  if mountpoint -q "$mp"; then GOOD="$GOOD $pair"; continue; fi
  mkdir -p "$mp"
  # Immutable while unmounted: if the NAS is down, nothing can land on the laptop's disk by mistake.
  chattr +i "$mp" 2>/dev/null || true
  if mount -t cifs "//$NAS/$share" "$mp" -o "$OPTS"; then
    GOOD="$GOOD $pair"
  else
    SKIPPED="$SKIPPED $share"
  fi
done

cp -a /etc/fstab "/etc/fstab.bak-shinas-$(date +%Y%m%d-%H%M%S)"
sed -i "/^$BEGIN\$/,/^$END\$/d" /etc/fstab
{
  echo "$BEGIN"
  for pair in $GOOD; do
    echo "//$NAS/${pair##*:} $ROOT/${pair%%:*} cifs $OPTS 0 0"
  done
  echo "$END"
} >> /etc/fstab
systemctl daemon-reload

echo; echo "Mounted:"; findmnt -t cifs -o TARGET,SOURCE -n
[ -z "$SKIPPED" ] || echo "Not mounted:$SKIPPED"
echo; echo "SHINAS_MOUNT_DONE. Tell Aya it finished."
