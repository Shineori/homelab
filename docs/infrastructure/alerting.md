# Alerting & email

| What | Source | Where it goes |
|---|---|---|
| Security events | auditd → Python plugin ([security monitoring](../services/security-monitoring.md)) | Discord security channel |
| New image versions | [Diun](../services/diun.md) on both servers | Discord #updates |
| Backup failures | [Backup scripts](backups.md) (NAS, laptop, and the NAS's weekly cleanup) | Discord #backups |
| Services down | [Uptime Kuma](../services/uptime-kuma.md) on ShineoriServer, watching both machines | Dashboard (Discord alerts planned) |

Each channel has its **own webhook**, so any one of them can be revoked without breaking the others. Webhooks live in root-only files and are passed to `curl` through stdin, never on the command line.

- Email: dedicated homelab Gmail account used as SMTP sender (app password, stored in Vaultwarden)
