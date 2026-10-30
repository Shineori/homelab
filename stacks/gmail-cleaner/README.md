# Gmail Cleaner stack

Docs: [`docs/services/gmail-cleaner.md`](../../docs/services/gmail-cleaner.md)

Source on the server: `~/docker/gmail-cleaner` (ShineoriServer)

Builds from my fork, [Shineori/gmail-cleaner](https://github.com/Shineori/gmail-cleaner), pinned to one commit.

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)
- `.env.example` (every value blanked)

Not in the repo, ever: `credentials.json` (Google OAuth client) and `data/` (Gmail token, protected list, undo history).
