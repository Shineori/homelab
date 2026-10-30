# Network

```mermaid
flowchart TB
    internet((Internet))
    cf[Cloudflare Tunnel]
    playit[playit.gg]
    subgraph LAN[Home LAN]
        nas[ShiNAS]
        srv[ShineoriServer]
        pc[Windows PC]
    end
    internet --> cf --> nas
    nas -. tunnel routes over LAN .-> srv
    internet --> playit --> srv
```

## Remote access strategy

| Method | Used for | Why |
|---|---|---|
| Cloudflare Tunnels (two) | One tunnel per domain: the main domain's tunnel runs on ShiNAS and also reaches ShineoriServer's apps over the LAN; a second domain has its own tunnel on ShineoriServer (see [Cloudflare Tunnel](../services/cloudflared.md)). NAS admin panel and the addy.io web UI gated by Cloudflare Access + Authentik. | No open ports, home IP hidden, HTTPS for free |
| playit.gg | Minecraft (Terraria used it too, now retired) | Raw TCP/UDP game traffic |
| LAN only | Flowcase, Uptime Kuma, Ghiro, Paperless, the *arr stack | Don't need to be on the internet |
| Backups | ShineoriServer → append-only restic server on ShiNAS (port 8500); Windows PC ← append-only `rest-reader` on ShiNAS (port 8501), both LAN-only | See [Backups](backups.md) |

## Conventions
- Containers run as PUID 1000 / PGID 100
- All stacks consolidated under `~/docker/<service>`
- Servers use fixed addresses that the tunnel routes and monitors depend on (real IPs are kept out of this public repo)
- Planned: VLANs to separate servers, personal devices and IoT, practiced first in the [OPNsense lab](../services/opnsense-lab.md)
