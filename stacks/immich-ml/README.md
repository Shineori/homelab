# Immich machine learning on ShineoriServer

Docs: [`docs/services/immich.md`](../../docs/services/immich.md)

Source on the server: `~/docker/immich-ml` (ShineoriServer)

Runs only Immich's machine-learning service (CPU-only, capped at 3 cores, model TTL 300 s), for the Immich server on ShiNAS. The image tag must match the server's Immich version. Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
