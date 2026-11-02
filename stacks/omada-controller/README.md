# Omada Controller stack

Docs: [`docs/services/omada-controller.md`](../../docs/services/omada-controller.md)

Source on the server: `~/docker/omada` (ShineoriServer)

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)

Certificate setup and renewal scripts: [`scripts/omada-cert-install.sh`](../../scripts/omada-cert-install.sh) and [`scripts/omada-cert-renew.sh`](../../scripts/omada-cert-renew.sh). The token and certificate files stay in `/etc/omada-cert` on the server and are never committed.
