# Diun (update notifications)

> Watches every container image in the lab and pings Discord when a new stable version ships. It never installs anything by itself.

| | |
|---|---|
| **Host** | ShiNAS |
| **Category** | Networking & monitoring |
| **Status** | 🟢 running |
| **Exposed?** | No. Outbound only (container registries + a Discord webhook) |
| **Version** | 4.33.0 (pinned) |

Compose file: [`stacks/diun/`](https://github.com/shineori/homelab/tree/main/stacks/diun)

## Why I run it

Most of my apps used to float on `:latest`, which meant any `docker compose pull` could silently upgrade them. That includes breaking changes, and makes "what changed?" hard to answer when something breaks. So I made a two-part change:

1. **Pin every image** to an exact version, so nothing changes until I decide.
2. **Run Diun**, so pinning doesn't mean missing updates. It tells me when a new version exists, and I upgrade on my own schedule.

```
🔔 Diun (awareness)                     📌 Pinned images (control)
every 6h: check registries for     ──▶  "immich-server v3.3.2 is out" → Discord
new stable version tags                  read release notes → bump the tag → update
never installs anything                  roll back = change the tag back
```

## How the pinning was done (safely)

Pinning can go wrong if you guess a version number and accidentally *change* what's running. So I made it a verify-first process:

1. **Inventory:** read the real version label from every running container (`org.opencontainers.image.version`)
2. **Verify:** pull each proposed tag and compare its image ID with the running container's image. **14 of 14 matched**, so every pin was byte-for-byte what was already running.
3. **Digest pins** for 3 images with no usable version (one reported `latest`, another `main`): `tag@sha256:<digest>`, where the digest is the source of truth
4. **Apply** with a script that backs up every file first, then **validate** every compose file (`docker compose config -q`)
5. **No restarts needed:** the images were identical, so pinning changed nothing today, and only stops surprise changes tomorrow

Databases (Postgres, PostGIS, Redis/Valkey) stay **locked to their major version**, which is the usual convention. Major upgrades are the dangerous ones for databases, and those are already blocked.

## Configuration choices

| Setting | Why |
|---|---|
| `WATCHREPO: true` + `NOTIFYON: new` | Pinned tags never change, so Diun has to look for **new tags** in each repository instead of watching the current one |
| Include `^v?\d+\.\d+\.\d+` | Only real version numbers, which skips the dozens of variant tags database images publish |
| Exclude `rc / beta / alpha / dev / nightly / pre` | Stable releases only |
| `FIRSTCHECKNOTIF: false` | The first scan quietly records what exists, instead of announcing every historical version |
| Every 6 hours, 30s jitter | Frequent enough to be useful, gentle on registry rate limits |
| `hostname: shinas` | Notifications say which server they came from, ready for when I add Diun to my second server |
| A **separate Discord webhook and channel** | Update chatter stays out of my security-alerts channel, and either webhook can be revoked on its own |
| Webhook in a root-only `.env` | Entered with `read -s`, so it never touched the screen, my shell history, the compose file or git |

## Troubleshooting log

| Problem | Root cause | Fix |
|---|---|---|
| `403 Forbidden` listing tags for Karakeep's headless-Chrome image | That image lives on a Google registry that doesn't allow anonymous tag listing | Added the label `diun.enable=false` to that one service. It's pinned (`124`) and rarely updated. |

## What I'd harden next

- [ ] **Put a docker-socket-proxy in front of the Docker socket.** I first thought mounting the socket `:ro` made it "look but don't touch". **That's wrong:** `:ro` only stops the socket *file* from being replaced, and the Docker API behind it is still fully available. A socket proxy that only allows read-only `GET` requests for containers and images gives Diun exactly what it needs and nothing more. The same fix applies to Authentik's worker.
- [ ] Add Diun to my second server (ShineoriServer) too
- [ ] A monthly "update day": work through the Discord notifications, read the release notes, and bump the pins

## What I learned

- **Pinning is configuration management:** the compose files now describe *exactly* what runs, so a rebuild reproduces it
- **Verify before you change:** comparing image IDs proved the pins were no-ops before I applied them
- **Tags vs digests:** a tag is a movable label, and a digest is the content's fingerprint
- **Read-only isn't always read-only:** `:ro` on a socket protects the file, not the API behind it. I caught my own wrong assumption while writing this page.
