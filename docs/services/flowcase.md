# Flowcase

> Browser-based isolated workspaces (Kasm-style), routed through ProtonVPN

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Apps |
| **Status** | ⏸️ on demand (started only when I need it) |
| **Exposed?** | LAN only |

Compose file: [`stacks/flowcase/`](https://github.com/shineori/homelab/tree/main/stacks/flowcase)

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[Flowcase]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Migrated from a Windows PC to ShiNAS. It was published through the Cloudflare Tunnel at first, and is now **LAN only** because it doesn't need to be on the internet.
- Goal: workspace traffic exits through ProtonVPN so the real IP is hidden

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
