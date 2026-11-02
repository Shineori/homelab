#!/usr/bin/env bash
# Gets or renews the Omada Controller's Let's Encrypt certificate.
# The controller only reads /cert at startup, so it restarts only when the cert changed.
set -euo pipefail

BASE=/etc/omada-cert
IMAGE=certbot/dns-cloudflare:v5.9.0
source "$BASE/omada-cert.env"   # provides DOMAIN

docker run --rm \
  -v "$BASE/letsencrypt:/etc/letsencrypt" \
  -v "$BASE/cloudflare.ini:/cloudflare.ini:ro" \
  "$IMAGE" certonly \
  --non-interactive --agree-tos --register-unsafely-without-email \
  --keep-until-expiring --key-type rsa --rsa-key-size 2048 \
  --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  -d "$DOMAIN" "$@"

# A dry run only tests the setup and writes no certificate
[[ " $* " == *" --dry-run "* ]] && exit 0

LIVE="$BASE/letsencrypt/live/$DOMAIN"
if cmp -s "$LIVE/fullchain.pem" "$BASE/cert/tls.crt"; then
  echo "Certificate unchanged, no restart needed."
  exit 0
fi

install -m 644 "$LIVE/fullchain.pem" "$BASE/cert/tls.crt"
install -m 600 "$LIVE/privkey.pem" "$BASE/cert/tls.key"
echo "New certificate copied to $BASE/cert."

# Skip the restart until the controller actually mounts /cert
if docker inspect -f '{{range .Mounts}}{{.Destination}} {{end}}' omada-controller | grep -qw /cert; then
  docker restart -t 60 omada-controller
  echo "Controller restarted to load the new certificate."
fi
