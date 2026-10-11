# Moving services off the NAS

> My NAS ran out of RAM, so I moved six services to my second server without losing any data, and documented every snag along the way.

| | |
|---|---|
| **From** | ShiNAS (NAS appliance, 7.5 GB RAM) |
| **To** | ShineoriServer (repurposed laptop, 31 GB RAM, RTX 2060) |
| **Moved** | Immich machine learning, Uptime Kuma, Homarr, Dawarich, Karakeep, Ghiro |
| **When** | October 2026 |

## Why

The night before, the NAS **overloaded**: load average 36, swap almost full, and every app timing out (the full diagnosis is in the [Immich troubleshooting log](../services/immich.md#troubleshooting-log)). Capping Immich's machine-learning container fixed the crash, but the NAS was still tight:

```
ShiNAS: 7.5 GB total
├─ containers     ≈ 2.9 GB  (measured with docker stats)
├─ NAS system     ≈ 2.4 GB
├─ disk cache     ≈ 2.8 GB  (given back when apps need it)
└─ available      ≈ 2.2 GB  ← one ML job (up to 2 GB) or a video transcode used all of it
```

Meanwhile the laptop server had 31 GB of RAM and was mostly idle between AI chats.

## How I chose what moves

> 📦 **Big, irreplaceable data stays on the NAS. Apps that need lots of RAM but hold little data move.**

| Stays on ShiNAS 🔒 | Why |
|---|---|
| Immich (server + database), Paperless | Irreplaceable photos and documents, already in the nightly encrypted backup |
| Vaultwarden, Authentik | Identity and passwords: the most important services stay on the most reliable box |
| Jellyfin, Audiobookshelf, *arr stack, qBittorrent | They read and write the media on the NAS disks directly |
| Diun, resume site, cloudflared | Diun watches the host it runs on; the other two are tiny |

| Moved to ShineoriServer 🚚 | RAM on the NAS (idle) | Data |
|---|---|---|
| Immich machine learning | up to **2 GB** during jobs | none (model files only) |
| Dawarich (4 containers) | ~450 MiB | small Postgres database |
| Homarr | ~260 MiB | one small folder |
| Uptime Kuma | ~160 MiB | one SQLite file |
| Karakeep | headless Chrome + search engine | small |
| Ghiro | only while running | none |

**Uptime Kuma had a second reason:** a monitor running on the box it watches can't warn you when that box dies. During the overload it went down *with* the NAS instead of reporting it. Now it watches the NAS from outside, including a ping monitor for the NAS itself.

## How each one moved

Every move followed the same safety rule: **copy, start on the laptop, check, and only then switch traffic.** The NAS copy stayed untouched as a one-command rollback.

```
NAS: stop app ─▶ pack data ─▶ copy over SSH ─▶ laptop: unpack ─▶ start ─▶ check ─▶ repoint tunnel + monitors
                                                                                   (NAS copy kept for rollback)
```

| Service | Method | The interesting part |
|---|---|---|
| **Immich ML** | Nothing to copy | Immich can send ML work to another machine by URL. The NAS keeps the service definition behind a compose `profiles:` switch, so rolling back is one line. |
| **Uptime Kuma** | Folder copy | Stopped first, so SQLite's write-ahead log (`kuma.db-wal`) was merged into the database before copying |
| **Homarr** | Folder copy, including `.env` | The `.env` holds the encryption key for every saved integration secret. Without it, they come back unreadable. |
| **Dawarich** | **Docker volume export and import** | Its data lives in 5 Docker *named volumes*, not in its folder, so copying the folder alone would have produced an empty Dawarich. I exported each volume to a tarball with a throwaway container, then imported them into fresh volumes on the laptop. |
| **Karakeep** | Volume export and import | A port clash (Open WebUI already had 3000) and a dead image registry. See below. |
| **Ghiro** | Fresh install | It had no data, and the old image turned out to be damaged |

The volume trick, for reference:

```bash
# export (NAS): read the volume with an image that's already downloaded, so nothing new is pulled
docker run --rm --entrypoint tar -v dawarich_dawarich_db_data:/v:ro -v /tmp/move:/out \
  postgis/postgis:17-3.5-alpine czf /out/db_data.tgz -C /v .

# import (laptop): `docker compose create` makes the empty volumes, then fill them
docker run --rm --entrypoint tar -v dawarich_dawarich_db_data:/v -v ~/docker/move:/in \
  postgis/postgis:17-3.5-alpine xzf /in/db_data.tgz -C /v
```

## Troubleshooting log

| Problem | Root cause | Fix |
|---|---|---|
| The laptop couldn't download anything: `lookup ghcr.io ... i/o timeout` | Not DNS. The laptop could reach the router but not the internet. A **host-wide ProtonVPN WireGuard tunnel** (`wg-quick@proton`) was sending all traffic into a tunnel that had stopped passing traffic. It hid from `ip route` because WireGuard uses separate policy-routing rules (`ip rule`). | SearXNG already had its own VPN through gluetun, so the host-wide tunnel was redundant (a VPN inside a VPN). Brought it down and disabled it at boot. |
| `scp` from the NAS said *No such file or directory* for a file that existed | Newer `scp` uses SFTP, and the NAS locks SFTP into the shared folders, so its `/tmp` isn't the real `/tmp` | Streamed the file over plain SSH instead: `ssh nas 'cat /tmp/file.tgz' > file.tgz` |
| Karakeep's headless-Chrome image wouldn't download: *billing must be enabled* | The Google registry project hosting it stopped serving downloads. The NAS only had it because it was downloaded long ago. | Switched to the same image on Docker Hub (`docker.io/zenika/alpine-chrome:124`) |
| Karakeep's `NEXTAUTH_URL` was `http://localhost:3000` | A wrong value from the original setup, found while moving it | Set it to the public hostname |
| Dawarich login ended on a Cloudflare **502** | The tunnel route still pointed at the NAS, and I had started the login on the laptop's IP while Authentik returns you to the public hostname | Repointed the route; logins start from the public hostname |
| Homarr's Uptime Kuma widget returned **404** | With "no secrets", Homarr reads a status page with the slug `default`, which didn't exist | Created a status page and entered its slug |
| Homarr's tile still opened the old address | In Homarr, the *integration* (data for widgets) and the *app* (where the tile links) are stored separately | Updated the app's URL as well |
| `docker save` of Ghiro failed: a file missing from an image layer | The locally built image on the NAS was damaged, and its Dockerfile is based on long-retired Ubuntu 16.04 and Python 2 | It held no data, so: built fresh on the laptop first, then removed everything from the NAS (`docker compose down -v --rmi all`) |

## Result

```
ShineoriServer 💻 31 GB                   ShiNAS 🗄️ 7.5 GB
├─ Immich ML                              ├─ Immich, Paperless       (irreplaceable data)
├─ Uptime Kuma  (watches the NAS)         ├─ Vaultwarden, Authentik  (identity)
├─ Homarr                                 ├─ Jellyfin, Audiobookshelf, *arr stack
├─ Dawarich, Karakeep                     ├─ Diun, resume site, cloudflared
├─ Ghiro (on demand)                      └─ Flowcase (on demand)
└─ Ollama, Open WebUI, SearXNG, Minecraft
```

About 870 MiB of steady RAM use left the NAS, and more importantly the **up-to-2 GB spikes** from machine learning now land on a machine with room for them. One Cloudflare tunnel on the NAS still publishes apps on both machines.

## What I'd do next

- [ ] **Back up the laptop:** Dawarich, Karakeep, Uptime Kuma and Homarr aren't in the nightly restic run yet ([Backups](backups.md))
- [x] **Diun on the laptop** ✅ *Done:* same setup as the NAS, with alerts labeled `shineoriserver`
- [ ] **A DHCP reservation for the laptop**, so its address can't change under the services that point at it
- [ ] Make sure the laptop never sleeps (lid closed, on power), since it's a server now
- [ ] Delete the rollback copies left on the NAS after a few calm days
- [ ] GPU acceleration for Immich ML on the RTX 2060

## What I learned

- **Know where your data actually lives.** A folder copy is enough for bind mounts; named volumes need an export. Checking `docker volume ls` first saved me from moving an empty app.
- **Build the new copy before you delete the old one.** Every move kept a working rollback until the new copy was checked.
- **Read the routing table *and* the rules.** `ip route` looked normal while WireGuard's policy rules sent everything into a dead tunnel.
- **Images can disappear.** Something that runs fine today may be impossible to download again tomorrow, and you only find out when you move or rebuild.
- **Monitoring belongs outside what it monitors.**
