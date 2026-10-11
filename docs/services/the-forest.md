# The Forest dedicated server

> Vanilla The Forest dedicated server reached over Tailscale

| | |
|---|---|
| **Host** | Windows PC |
| **Category** | Game servers |
| **Status** | ⚫ retired <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | TODO: LAN only / Cloudflare Tunnel / playit / Tailscale |

Not a Docker stack (see setup notes below).

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[The Forest dedicated server]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Installed via SteamCMD
- Ports: steam 8766, game 27015, query moved to 27020; 4 slots, VAC off
- Fixed an instant crash (access violation in CSteamworks.dll): the server was loading the wrong config, so a stale query port stayed occupied and Steam init failed

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
