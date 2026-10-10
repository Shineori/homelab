# Vaultwarden

> Self-hosted Bitwarden server for passwords, TOTP and passkeys

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Security & identity |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | TODO: LAN only / Cloudflare Tunnel / playit / Tailscale |

Compose file: [`stacks/vaultwarden/`](https://github.com/shineori/homelab/tree/main/stacks/vaultwarden)

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[Vaultwarden]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Goal: keep passwords, TOTP and passkeys portable across phones/OSes

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
