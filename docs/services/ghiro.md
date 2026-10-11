# Ghiro

> Image forensics web app

| | |
|---|---|
| **Host** | ShineoriServer |
| **Category** | Apps |
| **Status** | 🟢 running <!-- 🟡 in progress / 🔵 planned / ⚫ retired --> |
| **Exposed?** | LAN only, started only when I need it |

Compose file: [`stacks/ghiro/`](https://github.com/shineori/homelab/tree/main/stacks/ghiro)

> 🚚 **Moved from ShiNAS to ShineoriServer** in October 2026 to free up RAM on the NAS. It was **reinstalled fresh** rather than moved: it held no data, and its old image on the NAS turned out to be damaged. Full story: [Moving services off the NAS](../infrastructure/migration.md).

## Why I run it

TODO: one or two sentences. What problem does this solve for you?

## Architecture

```mermaid
flowchart LR
    user[Me / friends] --> entry[TODO: tunnel or LAN]
    entry --> app[Ghiro]
    app --> data[(TODO: volume / database)]
```

## Setup notes

- TODO

TODO: the steps you'd need to rebuild this from scratch.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| TODO | | | |

## What I learned

TODO: the skill this proves (great for interviews).
