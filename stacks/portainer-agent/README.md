# Portainer agent stack (ShiNAS)

Docs: [`docs/services/portainer.md`](../../docs/services/portainer.md)

Source on the server: `~/docker/portainer-agent` (ShiNAS)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (lets Portainer on ShineoriServer manage the NAS's containers)

`.env` holds the shared agent secret, so it stays on the server.
