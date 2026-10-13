# Terminal resume site stack

Docs: [`docs/services/resume-site.md`](../../docs/services/resume-site.md)

Source on the server: `~/docker/resume-site` (ShiNAS)

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
- `nginx.conf` (the site's NGINX config: security headers, caching, hidden-file blocking)
