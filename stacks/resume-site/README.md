# Terminal resume site stack

Docs: [`docs/services/resume-site.md`](../../docs/services/resume-site.md)

Source on the server: `~/docker/resume-site` (ShiNAS)

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
- `nginx.conf` (copied by hand: security headers, CSP, dotfile blocking)

No `.env`: this stack has no secrets. The site files themselves (`site/`) aren't copied here.
