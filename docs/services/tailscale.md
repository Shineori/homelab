# Tailscale

> Private, encrypted remote access to my admin and personal apps from my own devices, plus one-off sharing with friends, without putting anything on the public internet

| | |
|---|---|
| **Host** | ShiNAS and ShineoriServer (installed from the package manager, runs as a host systemd service, not in Docker) |
| **Category** | Networking & monitoring |
| **Status** | 🟢 running |
| **Exposed?** | Tailnet only (my devices, plus machines I explicitly share) |
| **Version** | 1.104.4, updated by hand (auto-update can't work on this OS, see below) |

## Why I run it

After I put the NAS admin panel behind [Cloudflare Access](cloudflared.md), the NAS vendor's own desktop and phone app stopped being able to sign in through my public hostname. The app talks straight to the NAS API, so it has no way to complete a browser login through Access and Authentik, and it just reports "failed to connect".

I had three ways to get remote access back:

| Option | Why I did or didn't pick it |
|---|---|
| Cloudflare WARP + a private network route on my tunnel | Keeps Authentik as the gate, but everything goes through Cloudflare and needs more dashboard setup |
| The NAS vendor's own remote-access relay | Easiest, but my admin traffic would pass through the vendor's cloud |
| An Access "bypass" rule for the app | Rejected. It reopens the exact hole Access was added to close |
| **Tailscale** ✅ | Already installed on the NAS, traffic is usually direct device-to-device, and I can share *just the NAS* with a friend for big file transfers |

### What moved here on 2026-11-04

I audited my [Cloudflare Tunnel](cloudflared.md) routes and moved every app that only I use onto the tailnet. Apps that friends or outside services need stay on Cloudflare.

| App | Machine | Tailscale HTTPS port | Why it moved |
|---|---|---|---|
| NAS admin panel | ShiNAS | 8443 | The most sensitive thing in the lab, and I can reach it privately |
| [Jellyfin](jellyfin.md) | ShiNAS | 8444 | Only I use it, and Cloudflare's terms restrict streaming video through a public hostname |
| [SearXNG](ollama-stack.md) | ShineoriServer | 443 | It was open to anyone with no login |
| [Uptime Kuma](uptime-kuma.md) | ShineoriServer | 8443 | Its dashboard maps out my whole lab |
| [Karakeep](karakeep.md) | ShineoriServer | 8444 | Only I use it |

## Architecture

```mermaid
flowchart LR
    me([My phone / laptop<br/>Tailscale on]) -- WireGuard, usually direct --> nas[ShiNAS<br/>tailscaled]
    friend([A friend's PC]) -- shared node only --> nas
    nas --> app[NAS app sign-in<br/>and file shares]
    me -- WireGuard, usually direct --> srv[ShineoriServer<br/>tailscaled]
    nas --> nasapps[tailscale serve<br/>NAS panel, Jellyfin]
    srv --> srvapps[tailscale serve<br/>SearXNG, Uptime Kuma, Karakeep]
    ctl[(Tailscale coordination<br/>server)] -. keys + peer info only .-> me
    ctl -. keys + peer info only .-> nas
    ctl -. keys + peer info only .-> friend
```

- The coordination server only hands out keys and tells devices how to find each other. My actual traffic goes peer to peer when possible, or through an encrypted relay when not.
- The NAS app signs in using the NAS's Tailscale address instead of my public hostname, so Cloudflare Access is never in the path.
- **`tailscale serve`** gives each private app an HTTPS address with a valid certificate, reachable only from my tailnet. It's a separate listener in front of the app's normal port.
- The [Cloudflare Tunnel](cloudflared.md) still handles public web apps. Tailscale is only for private access.
- For privacy on the go, a separate [Proton exit node](proton-exit.md) on ShineoriServer lets my devices send their internet traffic out through ProtonVPN while staying on the tailnet.

## Security decisions

| Decision | Why |
|---|---|
| **`tailscale serve`, never Funnel** | Serve stays inside my tailnet. Funnel would publish the app to the internet, which defeats the point |
| **One single-address route, no full subnet router** | ShineoriServer advertises only its own LAN address as a `/32`, so the Omada Controller's real name and certificate work away from home. My devices still don't get a path to the rest of my home network. My main PC doesn't accept routes, so it keeps its direct LAN path. |
| **Test first, delete second** | I confirm the new address works on my phone and PC before removing the public route |
| **Only what needs friends stays public** | Immich, Audiobookshelf and Vaultwarden stay on Cloudflare because I share them or may share them with people outside my tailnet |
| Tailscale instead of an Access bypass | Remote access without weakening the Access policy on the admin panel |
| Share a single node with friends, not my whole tailnet | A friend can download from the NAS but can't see any of my other devices |
| Strong 2FA (passkey) on the account I sign into Tailscale with | With Tailscale, that login *is* the gate, so it has to be as strong as Authentik |
| Fixed the crash with a per-service systemd drop-in, not by editing the vendor's global config | The NAS OS owns `/etc/systemd/system.conf`. Its own services may rely on the setting, and an OS update could overwrite my change anyway |
| Installed the update with `dpkg` instead of `apt --fix-broken install` | The OS ships some of its own package builds on top of Debian. Letting apt "fix" them could break the NAS's web UI or file services |
| No `tailscale set --auto-update` on the NAS | It uses apt behind the scenes, which fails here. I update by hand during my weekly update check instead |

## Setup notes

1. Tailscale was already installed from the official apt repo and enabled as `tailscaled`.
2. Check it's up:
   ```bash
   systemctl is-active tailscaled
   tailscale status --self --peers=false
   ```
3. In the NAS app, sign in with the NAS's Tailscale address (or its MagicDNS name) instead of the public hostname.
4. To share with a friend: admin console → Machines → the NAS → Share. They accept the invite and only see that one machine.
5. **Updating on this NAS** (apt can't do it, see the troubleshooting log):
   ```bash
   cd /tmp
   apt-get download tailscale     # just downloads the newest .deb
   sudo dpkg -i tailscale_*.deb   # installs only Tailscale, no dependency solving
   rm tailscale_*.deb
   tailscale version              # client and daemon versions should match
   ```
6. **Moving an app onto the tailnet:**
   ```bash
   sudo tailscale set --operator=$USER   # once per machine, so serve works without sudo
   tailscale serve --bg --https=<port> http://127.0.0.1:<app_port>
   tailscale serve status
   ```
   For an app that already speaks HTTPS with a self-signed certificate, use `https+insecure://localhost:<app_port>` as the target. Avoid HTTPS ports another service already listens on. Update any setting that stores the app's address, test on every device, then delete the tunnel route and its DNS record.
7. **On the phone:** turn on VPN On Demand in the Tailscale app, so it reconnects on its own.
8. The drop-in that keeps the daemon starting:
   ```ini
   # /etc/systemd/system/tailscaled.service.d/no-godebug.conf
   [Service]
   UnsetEnvironment=GODEBUG
   ```
   Then `sudo systemctl daemon-reload && sudo systemctl restart tailscaled`.

## Troubleshooting log

| Problem | Root cause | Fix |
|---|---|---|
| The NAS app said "failed to connect" after I added Cloudflare Access | The app can't complete a browser-based Access + Authentik login, so it only ever sees the Access login page | Use the LAN address at home, and Tailscale when away |
| Linking the NAS to the vendor's account kept failing with "Failed to operate" | Done through the public hostname, the request didn't make it through the Access/tunnel path (I first guessed it was unrelated and was wrong) | Did it from the LAN address instead, and it worked first try. Admin setup now happens on the LAN |
| `apt install --only-upgrade tailscale` refused with a wall of unmet dependencies | The OS mixes its own package builds (one was even an Ubuntu build) with Debian's, so apt wants to "fix" everything before installing anything | Downloaded only the Tailscale `.deb` and installed it with `dpkg -i`. Tailscale is a static binary, so it needs nothing else |
| After the update, `tailscale version` warned the client and daemon versions didn't match | The package updated the files, but the old daemon was still running from memory | Restart the service |
| The restart failed: `fatal error: removed GODEBUG "tlskyber" set to old value "0"`, exit code 2, five fast retries, then systemd gave up | The NAS OS sets `GODEBUG=tlskyber=0` for **every** service in `system.conf`. Newer Go versions removed that option and refuse to start when they see it. The old Tailscale was built with older Go, so it never cared. It ran fine when tested over SSH because my shell didn't load that setting | Added a drop-in with `UnsetEnvironment=GODEBUG` for `tailscaled` only, then `daemon-reload`, `reset-failed`, `restart`. Back up on 1.104.4 |
| `tailscale serve` said `Access denied: serve config denied` | Changing the serve config needs root or an approved operator | Ran `sudo tailscale set --operator=$USER` once on each server |
| The Windows client was stuck in `NoState` with "Access is denied", and devices showed it offline | The local service had gotten stuck, and restarting it needs an elevated prompt | Ran `Restart-Service Tailscale` in an admin PowerShell, and it came back |

## What I'd harden next

- [ ] Add the same `UnsetEnvironment=GODEBUG` drop-in to `cloudflared` and `docker` *before* they get a newer-Go build. Otherwise an update would take down the tunnel or every container the same way
- [ ] Disable key expiry on the NAS node so it doesn't silently log out while I'm away from home
- [ ] Remove stale devices from the tailnet (several haven't been seen in 4 to 9 months)
- [ ] Write tailnet ACLs so shared friends can only reach the file-sharing ports, not the admin panel
- [x] **ShineoriServer is on the tailnet** ✅ *Done:* it now serves SearXNG, Uptime Kuma and Karakeep
- [x] **Removed the public NAS admin route** ✅ *Done 2026-11-04:* the panel is only reachable on the LAN and over Tailscale

## What I learned

- **"Works in my shell" isn't "works as a service."** systemd gives services their own environment, and a vendor can inject variables into every one of them. Comparing my SSH test with the service's behavior is what pointed at the environment
- **Read the journal first.** The real error was one line in `journalctl`, while `systemctl status` only showed "exit code 2"
- **Vendor Linux isn't plain Debian.** On an appliance OS, apt's suggestions can be traps. Touch only the package you need, and leave system updates to the vendor's updater
- **Fix narrowly.** A drop-in for one service beats editing a global config I don't own, and it survives both OS and package updates
- **Choose the path by who needs access.** A public address is for people or services outside my devices. Everything else can stay private
- **Migrations need a rollback moment.** Keeping the old route until the new address passed on real devices meant nothing was ever unreachable
- **Zero Trust has side effects.** Putting a login wall in front of something can break the clients that talk to it, so plan a private access path alongside it
