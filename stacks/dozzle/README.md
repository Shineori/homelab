# Dozzle hub stack

Docs: [`docs/services/dozzle.md`](../../docs/services/dozzle.md)

Source on the server: `~/docker/dozzle` (ShineoriServer)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (the web UI; connects to the agent on ShiNAS)

`certs/` and `data/` hold the private key and logins, so they stay on the server.
