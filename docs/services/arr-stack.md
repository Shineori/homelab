# *arr stack

> Prowlarr + arr apps + qBittorrent routed through gluetun/ProtonVPN

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Media |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | TODO: LAN only / Cloudflare Tunnel / playit / Tailscale |

Compose file: [`stacks/arr-stack/`](https://github.com/shineori/homelab/tree/main/stacks/arr-stack)

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[*arr stack]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- qBittorrent here runs through gluetun (ProtonVPN)

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
