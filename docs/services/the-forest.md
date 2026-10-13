# The Forest dedicated server

> Vanilla The Forest dedicated server reached over Tailscale

| | |
|---|---|
| **Host** | Windows PC |
| **Category** | Game servers |
| **Status** | ⚫ retired |
| **Exposed?** | Was: Tailscale only (private, friends-only) |
| **Config** | Vanilla, 4 player slots, anonymous Steam account, VAC off |

Not a Docker stack (see setup notes below).

## Why I ran it

A private The Forest server so my friends and I could play together without one of us having to host the game. It's offline now, and the write-up stays because the crash fix was a good root-cause investigation.

## Architecture

```mermaid
flowchart LR
    friends([Friends on Tailscale]) --> ts[Tailscale<br/>private network]
    ts --> srv[The Forest dedicated server<br/>Windows 11 · SteamCMD]
    srv --> cfg[(server.cfg<br/>ports, slots, settings)]
```

| Port | Use |
|---|---|
| 8766 | Steam |
| 27015 | Game |
| 27020 | Query (moved from its default, see the troubleshooting log) |

## Security decisions

| Decision | Why |
|---|---|
| **Tailscale instead of port forwarding** | Only friends on my private Tailscale network could reach it; nothing was open to the internet |
| **`serverIP` set to the Tailscale address** | The server listened on the private network, not the public one |
| **Anonymous Steam account** | No Steam login stored on the server |

## Setup notes

1. Install SteamCMD and download the dedicated server with it
2. Edit `server.cfg`: ports, 4 slots, `serverIP` set to the machine's Tailscale address
3. Make sure the server is launched with **that** config file (see below)
4. Friends join over Tailscale

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| 2026-09 | The server crashed about 2 seconds after every launch, with an access violation in `CSteamworks.dll` | It was loading the **wrong config file**. With the stale settings, the query port was already in use, so Steam's server initialisation failed and left the game with a broken Steam interface, which crashed it. | Pointed the server at the correct config and moved the query port to 27020 |

## What I learned

- **Root cause over symptoms:** the crash was in a Steam DLL, but the real cause was one step earlier, a config file being read from the wrong place
- **Read the startup sequence:** port in use → Steam init fails → crash later. Following that chain found the fix.
- **Private networking with Tailscale** as an alternative to opening ports
