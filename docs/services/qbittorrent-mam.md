# qBittorrent (standalone)

> Separate qBittorrent instance with tracker-specific rules

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Media |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | Web UI LAN only (not published through the tunnel) |

Compose file: [`stacks/qbittorrent-mam/`](https://github.com/shineori/homelab/tree/main/stacks/qbittorrent-mam)

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[qBittorrent (standalone)]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Intentionally separate from the VPN'd arr-stack instance because the tracker's rules require it
- Fixed port mappings

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
