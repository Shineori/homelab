# Dozzle agent stack (ShiNAS)

Docs: [`docs/services/dozzle.md`](../../docs/services/dozzle.md)

Source on the server: `~/docker/dozzle-agent` (ShiNAS)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (streams the NAS's container logs to the hub on ShineoriServer)

`certs/` holds the private key, so it stays on the server.
