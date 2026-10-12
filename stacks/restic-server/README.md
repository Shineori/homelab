# restic rest-server stack

Docs: [`docs/infrastructure/backups.md`](../../docs/infrastructure/backups.md#shineoriserver-backups-append-only)

Source on the server: `~/docker/restic-server` (ShiNAS)

Append-only backup target for ShineoriServer. Users are created with `docker exec -it restic-rest-server create_user <name>` (stored in `.htpasswd` next to the data, never in this repo).

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
