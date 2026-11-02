#!/usr/bin/env bash
# One-time setup: real HTTPS certificate for the Omada Controller.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run this with sudo."; exit 1; }

DOMAIN=omada.example.com   # set to your own name
LAN_IP=192.168.0.10       # set to the controller host
HOME_DIR="$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)"
OMADA_DIR="$HOME_DIR/docker/omada"
BASE=/etc/omada-cert
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== 1/6 Checking DNS =="
getent hosts "$DOMAIN" | grep -q "$LAN_IP" || {
  echo "$DOMAIN does not point at $LAN_IP yet. Add the DNS-only record, wait a minute, rerun."
  exit 1
}
echo "OK: $DOMAIN -> $LAN_IP"

echo "== 2/6 Creating private folders =="
install -d -m 700 "$BASE" "$BASE/letsencrypt" "$BASE/cert" "$BASE/rollback"
echo "DOMAIN=$DOMAIN" > "$BASE/omada-cert.env"
install -m 755 "$HERE/omada-cert-renew.sh" /usr/local/bin/omada-cert-renew

if [[ ! -s "$BASE/cloudflare.ini" ]]; then
  read -rsp "Paste your Cloudflare API token (hidden), then press Enter: " TOKEN; echo
  ( umask 077; printf 'dns_cloudflare_api_token = %s\n' "$TOKEN" > "$BASE/cloudflare.ini" )
  unset TOKEN
fi

echo "== 3/6 Test run against Let's Encrypt staging =="
/usr/local/bin/omada-cert-renew --dry-run

echo "== 4/6 Getting the real certificate =="
/usr/local/bin/omada-cert-renew
openssl x509 -in "$BASE/cert/tls.crt" -noout -subject -issuer -enddate

echo "== 5/6 Adding the certificate to the compose file =="
cd "$OMADA_DIR"
if ! grep -q '/cert:ro' docker-compose.yml; then
  cp -a docker-compose.yml "$BASE/rollback/docker-compose.yml.bak"
  docker cp omada-controller:/opt/tplink/EAPController/data/keystore/eap.keystore "$BASE/rollback/eap.keystore.bak"
  sed -i "s#^\( *\)- ./omada-logs:/opt/tplink/EAPController/logs#&\n\1- $BASE/cert:/cert:ro#" docker-compose.yml
  grep -q '/cert:ro' docker-compose.yml || { echo "Compose edit failed, nothing restarted."; exit 1; }
  docker compose config -q || { cp -a "$BASE/rollback/docker-compose.yml.bak" docker-compose.yml; echo "Invalid compose, restored it."; exit 1; }
fi

echo "== 6/6 Restarting the controller and scheduling renewal =="
read -rp "Controller backup downloaded, and OK to restart it now? Type yes: " OK
[[ "$OK" == "yes" ]] || { echo "Stopped before restart. Rerun this script when ready."; exit 0; }
docker compose up -d

cat > /etc/systemd/system/omada-cert-renew.service <<'UNIT'
[Unit]
Description=Renew Omada Controller certificate
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/omada-cert-renew
UNIT

cat > /etc/systemd/system/omada-cert-renew.timer <<'UNIT'
[Unit]
Description=Weekly Omada Controller certificate check

[Timer]
OnCalendar=Sun 09:30 UTC
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now omada-cert-renew.timer
echo
echo "Done. The controller takes a few minutes to boot, then open https://$DOMAIN:8043"
