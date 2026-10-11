# 🏠 Hasaam's Homelab

Documentation for everything I self-host: a NAS appliance (**ShiNAS**), a repurposed laptop (**ShineoriServer**), and lab VMs on my Windows PC.

```mermaid
flowchart LR
    subgraph ShiNAS
        A[Identity & security]
        B[Media]
        C[Apps]
        D[Game servers]
    end
    subgraph ShineoriServer
        E[Minecraft]
        F[Local AI]
    end
    subgraph Windows PC
        G[Security labs]
        H[The Forest]
    end
```

## ⭐ Featured write-ups

Deep dives with architecture, security decisions, troubleshooting and lessons learned:

| Write-up | Highlights |
|---|---|
| 🌐 [Cloudflare Tunnel](docs/services/cloudflared.md) | Zero open ports, a **security audit of my own setup** (5 findings, all fixed), Zero Trust gate on the NAS admin panel |
| 🔐 [Authentik SSO](docs/services/authentik.md) | Self-hosted identity provider, passwordless passkeys, OIDC into my apps |
| 🛡️ [auditd + Discord alerts](docs/services/security-monitoring.md) | Kernel-level audit rules mapped to attacker goals, real-time alerting through an auditd plugin I wrote |

## Services

**Status legend**

| | Status | Meaning |
|---|---|---|
| 🟢 | Running | Live and in daily use |
| 🟡 | In progress | Being built or still being configured |
| 🔵 | Planned | Researched and on the roadmap, not built yet |
| ⚫ | Retired | Shut down, kept here for the write-up and lessons learned |

### Security & identity

| Service | Host | Status | What it does |
|---|---|---|---|
| [Authentik](docs/services/authentik.md) | ShiNAS | 🟢 | Single sign-on and identity provider for the lab |
| [Vaultwarden](docs/services/vaultwarden.md) | ShiNAS | 🟢 | Self-hosted Bitwarden server for passwords, TOTP and passkeys |
| [auditd + Discord alerts](docs/services/security-monitoring.md) | ShiNAS | 🟢 | Host-level audit logging with real-time Discord webhook alerts |

### Networking & monitoring

| Service | Host | Status | What it does |
|---|---|---|---|
| [Cloudflare Tunnel](docs/services/cloudflared.md) | ShiNAS | 🟢 | Publishes selected services to the internet with no open ports |
| [Omada Controller](docs/services/omada-controller.md) | ShiNAS | 🟢 | Manages TP-Link Omada network gear |
| [Homarr](docs/services/homarr.md) | ShiNAS | 🟢 | Dashboard / home screen for every service |
| [Uptime Kuma](docs/services/uptime-kuma.md) | ShiNAS | 🟢 | Uptime monitoring and alerts for every service |

### Media

| Service | Host | Status | What it does |
|---|---|---|---|
| [Jellyfin](docs/services/jellyfin.md) | ShiNAS | 🟢 | Media server for movies and shows |
| [Immich](docs/services/immich.md) | ShiNAS | 🟢 | Self-hosted Google Photos replacement |
| [*arr stack](docs/services/arr-stack.md) | ShiNAS | 🟢 | Prowlarr + arr apps + qBittorrent routed through gluetun/ProtonVPN |
| [qBittorrent (standalone)](docs/services/qbittorrent-mam.md) | ShiNAS | 🟢 | Separate qBittorrent instance with tracker-specific rules |
| [Audiobookshelf](docs/services/audiobookshelf.md) | ShiNAS | 🟢 | Audiobook and podcast server |

### Apps

| Service | Host | Status | What it does |
|---|---|---|---|
| [Dawarich](docs/services/dawarich.md) | ShiNAS | 🟢 | Self-hosted location history (Google Timeline replacement) |
| [Flowcase](docs/services/flowcase.md) | ShiNAS | 🟢 | Browser-based isolated workspaces (Kasm-style), routed through ProtonVPN |
| [Ghiro](docs/services/ghiro.md) | ShiNAS | 🟢 | Image forensics web app |
| [Paperless-ngx](docs/services/paperless.md) | ShiNAS | 🟢 | Scans, OCRs and organizes documents so they're searchable |
| [Karakeep](docs/services/karakeep.md) | ShiNAS | 🟢 | Self-hosted bookmark and read-it-later manager |

### Game servers

| Service | Host | Status | What it does |
|---|---|---|---|
| [Terraria (tModLoader)](docs/services/terraria.md) | ShiNAS | ⚫ | Modded Terraria server for friends, public via playit.gg |
| [Minecraft + playit](docs/services/minecraft.md) | ShineoriServer | 🟢 | Minecraft server with playit.gg tunnel |
| [The Forest dedicated server](docs/services/the-forest.md) | Windows PC | 🟢 | Vanilla The Forest dedicated server reached over Tailscale |

### AI

| Service | Host | Status | What it does |
|---|---|---|---|
| [Ollama + Open WebUI + SearXNG](docs/services/ollama-stack.md) | ShineoriServer | 🟢 | Local LLM stack with private web search |
| [Hermes Agent](docs/services/hermes-agent.md) | Windows PC | 🔵 | Local AI agent for diagnosing the PC (planned) |

### Security labs

| Service | Host | Status | What it does |
|---|---|---|---|
| [Pentesting lab](docs/services/pentest-lab.md) | Windows PC | 🟢 | Attacker/target lab for practicing offensive security legally |
| [OPNsense router lab](docs/services/opnsense-lab.md) | Windows PC | 🟡 | Virtual OPNsense router in VMware Workstation Pro, rehearsal for a NUC router |
| [EVE-NG](docs/services/eve-ng.md) | Windows PC | 🟡 | Network emulation lab (Community Edition) |

### Web

| Service | Host | Status | What it does |
|---|---|---|---|
| [Terminal resume site](docs/services/resume-site.md) | ShiNAS | 🟡 | Interactive terminal-style resume served from NGINX in Docker |

## Infrastructure
- [Hardware](docs/infrastructure/hardware.md)
- [Network & remote access](docs/infrastructure/network.md)
- [Single sign-on](docs/infrastructure/sso.md)
- [Backups](docs/infrastructure/backups.md)
- [Alerting & email](docs/infrastructure/alerting.md)

---
📖 Rendered docs site: https://shineori.github.io/homelab/
