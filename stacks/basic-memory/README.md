# Basic Memory (remote MCP)

Docs: [`docs/services/basic-memory.md`](../../docs/services/basic-memory.md)

Source on the server: `~/basic-memory-remote` (ShineoriServer). Not Docker: it runs as a systemd user service.

Files here (copied by hand, domains redacted):
- `serve.py`
- `basic-memory-remote.service` (goes in `~/.config/systemd/user/`)
- `env.example` (fill in as `~/.config/basic-memory-remote/env`, `chmod 600`)
