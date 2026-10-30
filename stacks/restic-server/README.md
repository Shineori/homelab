# restic rest-server stack

Docs: [`docs/infrastructure/backups.md`](../../docs/infrastructure/backups.md#shineoriserver-backups-append-only)

Source on the server: `~/docker/restic-server` (ShiNAS)

Two containers from the same image:

| Service | Port | Mode | Who uses it |
|---|---|---|---|
| `rest-server` | 8500 | `--append-only --private-repos` | ShineoriServer pushes its nightly backups here |
| `rest-reader` | 8501 | `--append-only` | My Windows PC pulls a third copy of **both** repos ([details](../../docs/infrastructure/backups.md#copy-3-off-site-windows-pc-icloud)) |

Both are bound to the NAS's LAN IP only. Neither login can delete or overwrite anything.

- `rest-server` users are created with `docker exec -it restic-rest-server create_user <name>` (stored in `.htpasswd` next to the data, never in this repo).
- `rest-reader` has its own login file, `reader.htpasswd`, next to the compose file (`chmod 600`, never in this repo). It was made with `htpasswd -niB windows-pc` from the same image, with the password piped in from a locked file so it never showed on screen.

Files here:
- `docker-compose.yml` (copied by `scripts/collect-stacks.sh`)