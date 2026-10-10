# Dawarich

> Self-hosted location history (Google Timeline replacement)

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Apps |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | TODO: LAN only / Cloudflare Tunnel / playit / Tailscale |

Compose file: [`stacks/dawarich/`](https://github.com/shineori/homelab/tree/main/stacks/dawarich)

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[Dawarich]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Published through the Cloudflare Tunnel
- Authentik SSO with custom email-verified scope mapping

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
