# Terraria (tModLoader)

> Modded Terraria server for friends, public via playit.gg

| | |
|---|---|
| **Host** | ShiNAS |
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
    entry --> app[Terraria (tModLoader)]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- Retired: stopped hosting once the group stopped playing
- Custom modpack; Large + Master Mode world
- Diagnosed crash loops down to specific mods (TerrariaAmbience, TerrariaAmbienceAPI, PermaBuffs)
- Temporarily migrated to vanilla during debugging

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
