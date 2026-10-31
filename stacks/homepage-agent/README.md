# Homepage agent stack (ShiNAS)

Docs: [`docs/services/homepage.md`](../../docs/services/homepage.md)

Source on the server: `~/docker/homepage-agent/shinas-agent` (ShiNAS)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (read-only docker-socket-proxy + Glances, so Homepage can see the NAS)
