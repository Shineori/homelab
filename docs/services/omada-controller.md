# Omada Controller

> Manages TP-Link Omada network gear

| | |
|---|---|
| **Host** | ShineoriServer |
| **Category** | Networking & monitoring |
| **Status** | ⏸️ on demand (started only when I need it) |
| **Exposed?** | LAN only, with a real HTTPS certificate on a private DNS name |
| **Version** | 6.3.0.111 (`mbentley/omada-controller`, pinned) |

Compose file: [`stacks/omada-controller/`](https://github.com/shineori/homelab/tree/main/stacks/omada-controller)

## Why I run it

My network gear is managed from an Omada controller. Instead of buying TP-Link's hardware controller, I run the software version in Docker and start it only when I need to change something. The access points keep working without it.

It used to live on the NAS. I moved it to ShineoriServer along with the other apps that don't need the NAS disks, since the NAS is short on RAM.

## Architecture

```mermaid
flowchart LR
    me([Me, on the LAN]) --> ctl[Omada Controller v6<br/>host network]
    ctl -- discovery + adoption --> gear[Omada access points / switches]
    gear -- "device link (TCP 29817, new in v6)" --> ctl
    ctl --> data[(./omada-data<br/>MongoDB 8 + settings)]
    ctl --> logs[(./omada-logs)]
```

The web page uses a real certificate, which renews on its own:

```mermaid
flowchart LR
    timer[Weekly systemd timer] --> certbot[Certbot container]
    certbot -- "DNS-01 challenge" --> cf[Cloudflare DNS]
    cf --> le[Let's Encrypt]
    le --> folder[(/etc/omada-cert/cert<br/>root only)]
    folder -- "read at startup,<br/>restarts only if changed" --> ctl[Omada Controller]
```

## Security decisions

| Decision | Why |
|---|---|
| **LAN only, on demand** | A controller that can reconfigure the whole network shouldn't be reachable from outside, or running when nobody's using it |
| **`network_mode: host`** | Device discovery uses broadcast traffic on the local network, which Docker's default bridge network blocks. It also means new ports like v6's 29817 work without any compose change. |
| **`stop_grace_period: 60s`** | Gives the built-in MongoDB time to shut down cleanly, so the database isn't corrupted on stop |
| **Pinned exact version** | `latest` on this image stays on v5 on purpose, so pinning is the only way to get v6, and upgrades happen on my schedule |
| **Cloud access off** | I sign in locally and reach the controller over my own VPN when I'm away, so there's no need for a path through the vendor's cloud |
| **Separate guest and IoT VLANs** | Guests and smart devices get internet access but are blocked by firewall rules from starting connections to the home network, which limits what a compromised device can reach |
| **Printer discovery with mDNS** | Devices on the home network can still find the printer after it moves to the IoT VLAN, without opening the whole VLAN back up |
| **DNS-01 certificate** | Let's Encrypt can check domain ownership through a DNS record, so the controller gets a trusted certificate without being reachable from the internet |
| **DNS-only record to a private IP** | The name resolves to a LAN address and skips Cloudflare's proxy. Anyone can see the private IP, but they can't reach it from outside. |
| **API token limited to DNS on one zone** | Renewal only needs to create DNS records, so a leaked token can't touch the rest of the account. It still controls that zone's DNS, so it stays in a root-only file. |
| **Secrets kept in `/etc/omada-cert`** | The token and private key stay outside the stack folder, so they can't end up in this public repo or the app backups |
| **`/cert` folder, not the web upload** | The image builds its keystore from `/cert` at startup, which can be automated. A certificate uploaded in the web page goes into MongoDB, and the `/cert` method then stops working. |
| **`ulimits: nofile 65536`** | The database is thousands of small files. Docker's default limit of 1,024 open files crashed the MongoDB upgrade (see the troubleshooting log). |

## Setup notes

1. `docker compose up -d` and wait a few minutes on first start (it initialises MongoDB)
2. Open the controller's web page on the server's address (port 8043) and run the setup wizard
3. Adopt the devices. They remember the controller's address, so moving the controller to another machine means the devices have to find it again.
4. Moved from `/opt/omada` into the standard `~/docker` layout during the consolidation, then from the NAS to ShineoriServer
5. **Upgrading v5 to v6:** v6 needs MongoDB 8 instead of 3.6. With the controller stopped and its data backed up, run the image author's one-shot migration container, then change the tag:

```bash
docker compose down
sudo tar -czf ~/omada-data-backup.tar.gz -C ~/docker/omada omada-data
docker run -it --rm --ulimit nofile=65536:65536 \
  -v ~/docker/omada/omada-data:/opt/tplink/EAPController/data \
  mbentley/omada-controller:mongodb-upgrade-3.6-to-8
# set image: mbentley/omada-controller:6.3.0.111, then
docker compose up -d
```

6. **Real HTTPS certificate:** take a controller backup, then add a DNS-only A record pointing your chosen name at the server, and create a Cloudflare token with DNS edit rights on that one zone. Set the name and IP at the top of [`scripts/omada-cert-install.sh`](https://github.com/shineori/homelab/blob/main/scripts/omada-cert-install.sh), keep it next to [`omada-cert-renew.sh`](https://github.com/shineori/homelab/blob/main/scripts/omada-cert-renew.sh), and run it with sudo. It tests against Let's Encrypt's staging server, gets the certificate, adds this line to the compose file, asks before restarting, and sets up the weekly timer:

```yaml
      - /etc/omada-cert/cert:/cert:ro
```

To roll back, restore the compose file and `eap.keystore` from `/etc/omada-cert/rollback`, then run `docker compose up -d`.

TP-Link's own Linux download (a `.tar.gz` installer that needs Java 17, MongoDB and jsvc on the host) is for bare-metal installs. It isn't needed with Docker.

## Troubleshooting log

| Date | Problem | Root cause | Fix |
|---|---|---|---|
| 2026-10-28 | The MongoDB 3.6 → 8 migration crashed at the 4.0 step with `WT_PANIC` and an invariant failure. It rolled itself back. | The real line in `mongodb_upgrade.log`: **`Too many open files`**. The repair step opens every collection and index file at once (about 6,500), and Docker's default limit is 1,024. Normal running never hit it because files are opened a few at a time. | Reran the migration with `--ulimit nofile=65536:65536`. Every step from 3.6 to 8.0 passed. Added the same limit to the compose file. |
| 2026-10-28 | v6 showed a "Port Access Required" popup for TCP 29817 | v6 added a new port for devices. The notice appears for everyone after upgrading. | Nothing to do: host networking exposes it, and a test connection from another LAN machine succeeded |
| 2026-11-02 | Browser refused the controller page with `ERR_CERT_AUTHORITY_INVALID` | The controller ships with a self-signed certificate for `localhost`, which nothing trusts | Issued a Let's Encrypt certificate over DNS-01 and loaded it through `/cert`. A test request now verifies the full chain. |

## What I'd harden next

- [x] Back up `./omada-data` (and export the controller's own backup) before any upgrade ✅ *Done for the v6 upgrade*
- [x] Replace the self-signed web certificate with a trusted one that renews on its own. *Done 2026-11-02*
- [x] Turn on the controller's auto backup (daily, keeps 7). *Done 2026-11-02*
- [x] Add those auto backup files to the nightly backup, so a copy lives off this machine. *Done 2026-11-05*
- [x] Create guest and IoT VLANs with firewall rules between them. *Done 2026-11-02*
- [ ] Finish moving smart devices to the IoT VLAN and test printing across VLANs
- [ ] Give the servers their own VLAN
- [ ] Add an Uptime Kuma certificate-expiry alert, so a failed renewal gets noticed before the certificate runs out
- [ ] Remove the two unused named volumes declared at the bottom of the compose file (the stack uses folders instead)
- [ ] Delete the old copy of the stack left on the NAS so the v5 controller can't be started there by accident
- [ ] Clean up the migration leftovers (`mongodb-preupgrade.tar` and the upgrade logs) once v6 has been stable for a while

## What I learned

- **Why some apps need host networking:** Layer 2 discovery doesn't cross Docker's bridge network
- **Clean shutdowns matter for databases** inside containers
- **Control planes vs data planes:** the access points keep forwarding traffic while the controller is off
- **Databases upgrade in steps.** MongoDB can't jump from 3.6 to 8; it has to pass through 4.0, 4.2, 4.4, 5.0, 6.0 and 7.0
- **A backtrace says where, the log says why.** The crash dump only showed the function that failed. The cause was one plain-English line further up the log.
- **Container limits are real limits.** `ulimit` inside a container is set by Docker, not by the app, and it can break things that work fine at normal load
- **A certificate proves a name, not an IP.** That's why the fix needed a DNS name first, even for a LAN-only app
- **DNS-01 vs HTTP-01:** proving ownership through DNS means nothing has to be opened to the internet
- **Certificate names are public.** Issued certificates go into public transparency logs, so a subdomain name isn't a secret even when the service is private
- **Packet counters can map a network.** An uplink's traffic roughly equals every other port combined, which helped identify a switch's router link without touching a cable
- **Unmanaged switches are invisible to the controller.** The topology view can show devices as directly attached when they aren't
- **`latest` doesn't always mean newest.** This image keeps `latest` on v5 so a major upgrade can't happen by surprise
