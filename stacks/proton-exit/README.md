# Proton exit node stack

Docs: [`docs/services/proton-exit.md`](../../docs/services/proton-exit.md)

Source on the server: `~/docker/proton-exit` (ShineoriServer)

Files here:
- `.env.example` (the real `.env` is git-ignored; values blanked)
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
- `ts-state/` is never committed (it holds the node's Tailscale identity)
