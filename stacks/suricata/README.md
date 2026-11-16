# Suricata stack

Docs: [`docs/services/suricata.md`](../../docs/services/suricata.md)

Source on the server: `~/docker/suricata` (ShiNAS)

Network IDS that sniffs the NAS's interface and feeds alerts into [Wazuh](../../docs/services/wazuh.md).

Files here:
- `docker-compose.yml` — host-network Suricata on `eth0`, loading `local.rules` on top of the ET Open set
- `local.rules` — my own port-scan rule (on the server it lives at `lib/rules/local.rules`)

Rules and logs live in bind mounts (`./lib`, `./logs`) that are not in the repo.

To rebuild:

1. `mkdir -p ~/docker/suricata/logs ~/docker/suricata/lib`
2. put `docker-compose.yml` in `~/docker/suricata/` and `local.rules` in `~/docker/suricata/lib/rules/`
3. `docker compose run --rm suricata suricata-update` (fetch ET Open)
4. `docker compose up -d`
5. On the Wazuh agent, add a `json` `localfile` pointing at `~/docker/suricata/logs/eve.json`, and restart the agent

## Wazuh side

Two custom rules on the manager (`/var/ossec/etc/rules/local_rules.xml`) relate to this:
- `100110` (level 0) mutes the noisy "Ethertype unknown" Suricata decoder events
- the port scan then shows up through the Suricata rule `100001` (my `local.rules` SID) and the built-in ET SCAN rules

See [docs/services/suricata.md](../../docs/services/suricata.md) for the full reasoning.
