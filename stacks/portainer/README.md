# Portainer stack (ShineoriServer)

Docs: [`docs/services/portainer.md`](../../docs/services/portainer.md)

Source on the server: `~/docker/portainer` (ShineoriServer)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (the Portainer server and web UI)

`.env` holds the agent secret and `data/` holds Portainer's database, so both stay on the server.
