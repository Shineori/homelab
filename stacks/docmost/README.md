# Docmost stack

Docs: [`docs/services/docmost.md`](../../docs/services/docmost.md)

Source on the server: `~/docker/docmost` (ShineoriServer)

Files here (copied by `scripts/collect-stacks.sh`):
- `docker-compose.yml` (Docmost, Postgres and Redis)
- `.env.example` (`APP_URL`, `APP_SECRET` and `POSTGRES_PASSWORD`, values blanked)

`data/` holds the database, Redis and uploaded files, so it stays on the server.
