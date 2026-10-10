# Cloudflare Tunnel

> Publishes selected services to the internet with no open ports

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Networking & monitoring |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | TODO: LAN only / Cloudflare Tunnel / playit / Tailscale |

Not a Docker stack (see setup notes below).

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[Cloudflare Tunnel]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Publishes Flowcase, Immich, Dawarich and Authentik on subdomains
- Runs on the ShiNAS host as a CLI-installed cloudflared service, not a Docker container
- TODO: paste redacted ingress rules from /etc/cloudflared/config.yml (never the credentials JSON)

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
