# Ollama + Open WebUI + SearXNG

> Local LLM stack with private web search

| | |
|---|---|
| **Host** | ShineoriServer |
| **Category** | AI |
| **Status** | 🟢 running |
| **Exposed?** | Open WebUI through Cloudflare Tunnel (usually spun down); SearXNG LAN and Tailscale only since 2026-11-04, with its traffic leaving through ProtonVPN |
| **GPU** | RTX 2060 |

Compose file: [`stacks/ollama-stack/`](https://github.com/shineori/homelab/tree/main/stacks/ollama-stack)

## Why I run it

I wanted to run AI models on my own hardware, so my prompts never leave my network. Open WebUI gives it a ChatGPT-style interface, and SearXNG lets the models search the web without the search engines seeing my home IP.

## Architecture

```mermaid
flowchart LR
    me([Browser]) --> webui[Open WebUI<br/>:3000]
    me -- LAN or Tailscale --> g
    webui --> ollama[Ollama<br/>native systemd service · RTX 2060]
    webui -- web search --> g
    subgraph g[gluetun network stack]
        searx[SearXNG<br/>:8888]
    end
    g --> vpn{{ProtonVPN}} --> engines((Search engines))
    kk[Karakeep] -. AI tagging .-> ollama
```

| Piece | Job |
|---|---|
| **Ollama** | Runs the models on the GPU. It's installed **natively** (a systemd service on port 11432), not in Docker, so it has direct access to the GPU drivers. |
| **Open WebUI** | The chat interface. Reaches Ollama through `host.docker.internal`, which always means "this machine" even if its IP changes. |
| **SearXNG** | A private meta-search engine. It runs **inside gluetun's network stack**, so with no VPN it has no internet at all. |
| **searxng-nginx** | Front door on :8888. Proxies to SearXNG inside gluetun and injects my Google-style CSS (`searxng-nginx/custom/google.css`), so restyling never touches SearXNG itself. gluetun no longer publishes a port of its own. |
| **gluetun VPN protocol** | Chosen in `.env` (`VPN_TYPE=wireguard` or `openvpn`, falls back to OpenVPN), with exits pinned to nearby cities for low latency |
| **Shared with [Karakeep](karakeep.md)** | Karakeep uses the same Ollama for tagging bookmarks |

## Security decisions

| Decision | Why |
|---|---|
| **Local models only** | Prompts and documents stay on my hardware |
| **SearXNG behind a VPN with a kill switch** | Search engines see a ProtonVPN address, never my home IP |
| **SearXNG on LAN and [Tailscale](tailscale.md) only** | It has no login and its rate limiter is off so Open WebUI can use its API, so it must not be reachable from the internet |
| **VPN only for SearXNG, not the whole laptop** | Keeps everything else on the laptop on a normal connection (see the troubleshooting log for why that matters) |
| **No SSO on Open WebUI** | It's spun down most of the time, so I skipped connecting it to [Authentik](authentik.md) |
| **Secrets in a git-ignored `.env`** | `WEBUI_SECRET_KEY` and the ProtonVPN login |

## Setup notes

1. Install Ollama natively with the NVIDIA driver; it listens on port 11432
2. Fill `.env` with `WEBUI_SECRET_KEY` and the ProtonVPN OpenVPN credentials
3. `docker compose up -d`; Open WebUI at `http://<LAN_IP>:3000`, SearXNG at `http://<LAN_IP>:8888`
4. For access away from home: `tailscale serve --bg --https=443 http://127.0.0.1:8888`
5. Web search is pre-configured to `http://gluetun:8080/search?q=<query>`
6. Pull models with `ollama pull <model>`

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| 2026-10-11 | The laptop lost internet: Docker pulls failed with DNS timeouts | A second, **host-wide** ProtonVPN WireGuard tunnel had stopped passing traffic, and it was capturing everything. SearXNG already had its own VPN through gluetun, so this was a VPN inside a VPN. | Took the host-wide tunnel down and disabled it at boot. SearXNG stays private through gluetun. ([details](../infrastructure/migration.md#troubleshooting-log)) |
| 2026-11-04 | An audit found SearXNG publicly reachable with no login, even though this page said LAN only | A tunnel route existed that the docs didn't mention | Added a Tailscale address, tested it on my phone and PC, then deleted the route and DNS record |

## What I'd harden next

- [x] **Pinned SearXNG** ✅ *Done:* `2026.10.13-22c64b8d3` (it was on `:latest`, so it had already updated itself the last time the stack started)
- [ ] Pin Open WebUI (`:main`) and gluetun too
- [ ] Bind Open WebUI's port to the LAN IP instead of every interface
- [ ] Back up Open WebUI's chat history volume

## What I learned

- **GPU workloads:** why the model server runs natively while the web apps run in containers
- **Per-app VPN routing** with gluetun, instead of tunneling a whole machine
- **No login means no public route:** an app with no authentication of its own is only as private as the network path to it
- **WireGuard routing:** `ip route` can look normal while policy rules (`ip rule`) send everything into a dead tunnel
