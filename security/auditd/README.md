# auditd + Discord alerting

Write-up: [`docs/services/security-monitoring.md`](../../docs/services/security-monitoring.md)

| File | Lives on the server at | Purpose |
|---|---|---|
| `audit.rules` | `/etc/audit/rules.d/audit.rules` | The watch rules (loaded at boot, then locked with `-e 2`) |
| `discord.conf` | `/etc/audit/plugins.d/discord.conf` | Registers the script as an auditd plugin |
| `discord-alert.py` | `/etc/audit/discord-alert.py` | Reads events from stdin, filters them, posts to Discord |

The Discord webhook URL is redacted. These are copies of the live files, not a hardened release. See "What I'd harden next" in the write-up.
