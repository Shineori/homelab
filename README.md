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
        I[Immich ML]
        J[Monitoring & dashboard]
        K[Light apps]
    end
    subgraph Windows PC
        G[Security labs]
        H[The Forest]
    end
```

## ⭐ Featured write-ups

Full write-ups with architecture, security decisions, troubleshooting and lessons learned:

| Write-up | Highlights |
|---|---|
| 🌐 [Cloudflare Tunnel](docs/services/cloudflared.md) | Zero open ports, a **security audit of my own setup** (5 findings, all fixed), Zero Trust gate on the NAS admin panel |
| 🔐 [Authentik SSO](docs/services/authentik.md) | Self-hosted identity provider, passwordless passkeys, OIDC into my apps |
| 🛡️ [auditd + Discord alerts](docs/services/security-monitoring.md) | Kernel-level audit rules mapped to attacker goals, real-time alerting through an auditd plugin I wrote |
| 🔑 [Vaultwarden](docs/services/vaultwarden.md) | Self-hosted password manager with a zero-knowledge design; found and closed open public sign-ups, now invite-only |
| 🚚 [Moving services off the NAS](docs/infrastructure/migration.md) | Diagnosed a RAM-starved NAS and moved 6 services to a second server, including Docker volume migrations, a broken host VPN, a dead image registry and a damaged image |
| 📸 [Immich](docs/services/immich.md) | Multi-container photo platform: ML face recognition, vector smart search, SSO through Authentik |

## Services

**Status legend**

| | Status | Meaning |
|---|---|---|
| 🟢 | Running | Live and in daily use |
| 🟡 | In progress | Being built or still being configured |
| 🔵 | Planned | Researched and on the roadmap, not built yet |
| ⚫ | Retired | Shut down, kept here for the write-up and lessons learned |
| ⏸️ | On demand | Installed and working, but only started when I need it |

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
| [Tailscale](docs/services/tailscale.md) | ShiNAS | 🟢 | Private remote access to the NAS and friend file sharing, nothing public |
| [Omada Controller](docs/services/omada-controller.md) | ShineoriServer | ⏸️ | Manages TP-Link Omada network gear |
| [Homarr](docs/services/homarr.md) | ShineoriServer | 🟢 | Dashboard / home screen for every service |
| [Diun](docs/services/diun.md) | ShiNAS + ShineoriServer | 🟢 | Watches every container image and pings Discord when a new stable version ships |
| [Uptime Kuma](docs/services/uptime-kuma.md) | ShineoriServer | 🟢 | Uptime monitoring and alerts for every service |

### Media

| Service | Host | Status | What it does |
|---|---|---|---|
| [Jellyfin](docs/services/jellyfin.md) | ShiNAS | 🟢 | Media server for movies and shows |
| [Immich](docs/services/immich.md) | ShiNAS | 🟢 | Self-hosted Google Photos replacement |
| [*arr stack](docs/services/arr-stack.md) | ShiNAS | 🟢 | Prowlarr + arr apps + qBittorrent routed through gluetun/ProtonVPN |
| [qBittorrent (standalone)](docs/services/qbittorrent-mam.md) | ShiNAS | ⏸️ | Separate qBittorrent instance with tracker-specific rules |
| [Audiobookshelf](docs/services/audiobookshelf.md) | ShiNAS | 🟢 | Audiobook and podcast server |

### Apps

| Service | Host | Status | What it does |
|---|---|---|---|
| [Dawarich](docs/services/dawarich.md) | ShineoriServer | 🟢 | Self-hosted location history (Google Timeline replacement) |
| [Flowcase](docs/services/flowcase.md) | ShiNAS | ⏸️ | Browser-based isolated workspaces (Kasm-style), routed through ProtonVPN |
| [Ghiro](docs/services/ghiro.md) | ShineoriServer | ⏸️ | Image forensics web app |
| [Paperless-ngx](docs/services/paperless.md) | ShineoriServer | 🟢 | Scans, OCRs and organizes documents so they're searchable |
| [Karakeep](docs/services/karakeep.md) | ShineoriServer | 🟢 | Self-hosted bookmark and read-it-later manager |

### Game servers

| Service | Host | Status | What it does |
|---|---|---|---|
| [Terraria (tModLoader)](docs/services/terraria.md) | ShiNAS | ⚫ | Modded Terraria server for friends, public via playit.gg |
| [Minecraft + playit](docs/services/minecraft.md) | ShineoriServer | 🟢 | Fabric Minecraft server for Java + Bedrock (Geyser), playit.gg tunnels, BlueMap web map, daily backups |
| [The Forest dedicated server](docs/services/the-forest.md) | Windows PC | ⚫ | Vanilla The Forest dedicated server reached over Tailscale |

### AI

| Service | Host | Status | What it does |
|---|---|---|---|
| [Ollama + Open WebUI + SearXNG](docs/services/ollama-stack.md) | ShineoriServer | 🟢 | Local LLM stack with private web search |
| [Nimble + Decision Bridge](docs/services/nimble.md) | ShineoriServer + Windows PC | 🟢 | Local decision model that gives Claude typed yes/no, choice and score answers |
| [Hermes Agent](docs/services/hermes-agent.md) | ShineoriServer | ⚫ | Local AI agent that reads release notes and posts update verdicts in Discord, behind layered guardrails |

### Security labs

| Service | Host | Status | What it does |
|---|---|---|---|
| [Pentesting lab](docs/services/pentest-lab.md) | Windows PC | 🟢 | Attacker/target lab for practicing offensive security legally |
| [OPNsense router lab](docs/services/opnsense-lab.md) | Windows PC | 🟢 | Virtual OPNsense router in VMware Workstation Pro, rehearsal for a NUC router |
| [EVE-NG](docs/services/eve-ng.md) | Windows PC | 🟡 | Network emulation lab (Community Edition) |

### Web

| Service | Host | Status | What it does |
|---|---|---|---|
| [Terminal resume site](docs/services/resume-site.md) | ShiNAS | 🟢 | Interactive terminal-style resume served from NGINX in Docker |

## Infrastructure
- [Hardware](docs/infrastructure/hardware.md)
- [Network & remote access](docs/infrastructure/network.md)
- [Single sign-on](docs/infrastructure/sso.md)
- [Backups](docs/infrastructure/backups.md)
- [Minecraft world backups](docs/infrastructure/minecraft-backups.md)
- [Alerting & email](docs/infrastructure/alerting.md)

---
📖 Rendered docs site: https://shineori.github.io/homelab/
