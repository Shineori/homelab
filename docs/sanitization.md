# Before every push: sanitization checklist

Compose files often hardcode secrets in `environment:` blocks. The collector only blanks `.env` files, so check compose files by hand.

- [ ] No passwords, API keys, tunnel tokens, webhook URLs, app passwords
- [ ] Hardcoded `environment:` secrets moved to `.env` and referenced as `${VAR}`
- [ ] Decide on internal IPs, usernames, emails, subdomains (redact if public)
- [ ] `gitleaks detect --source . -v` comes back clean
- [ ] `git status` shows no `.env`, database or data folders

If a secret ever gets pushed: **rotate it first**, then clean history. Deleting the file is not enough.
