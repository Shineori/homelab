# Before every push: sanitization checklist

Compose files often hardcode secrets in `environment:` blocks. The collector only blanks `.env` files, so check compose files by hand.

- [ ] No passwords, API keys, tunnel tokens, webhook URLs, app passwords
- [ ] Hardcoded `environment:` secrets moved to `.env` and referenced as `${VAR}`
- [ ] Decide on internal IPs, usernames, emails, subdomains (redact if public)
- [ ] **No other people's personal details:** friends' names, gamertags, or anything named after someone (a modpack, a world, a server)
- [ ] `gitleaks detect --source . -v` comes back clean
- [ ] `git status` shows no `.env`, database or data folders

If a secret ever gets pushed: **rotate it first**, then clean history. Deleting the file is not enough.

## Incident: a friend's name in a public repo

> In October 2026 I found a friend's name in this public repo. Removing it took a history rewrite and, in the end, **deleting and recreating the repository**, which had **33 commits** at the time.

### What happened

While reviewing the docs, I noticed the [Terraria page](services/terraria.md) named the server's modpack, and the modpack was named after a friend. It had been there since the **very first commit**, in four slightly different lines across the page's versions. Gitleaks didn't catch it, because it isn't a secret: it's personal information about someone else, which no secret scanner looks for.

### How it was removed

```
1. edit the page     → name gone from today's files, but still in every old commit
2. rewrite history   → all 33 commits rewritten, force-pushed
3. check GitHub      → still reachable through pull-request refs and cached commits
4. recreate the repo → the only way to remove those for good
```

| Step | What I did | Why it wasn't enough on its own |
|---|---|---|
| **1. Edit the file** | Replaced the name with "custom modpack" and pushed | Git keeps every version. Anyone could click back through old commits and read it. |
| **2. Rewrite history** | Backed up the repo first, then ran `git filter-branch` over all **33 commits** to replace the name in every version of every file. Checked that no commit still contained it, and that today's files were identical to before. Force-pushed. | GitHub keeps **pull request refs** (`refs/pull/1`, `refs/pull/2`) that point at old commits, and owners can't delete them. Old commits also stayed viewable by their ID. |
| **3. Check the live site** | The docs site is rebuilt from scratch on every push, so it was already clean | |
| **4. Recreate the repo** | Saved every setting (description, topics, Pages, workflow permissions), deleted the repository, recreated it and pushed the clean history | This is the only step that removes the PR refs and cached commits. The cost: the record of two closed pull requests. |

### What I learned

- **Git never forgets by default.** Deleting a line only hides it from the latest version.
- **Secret scanners don't catch personal information.** Names, gamertags and nicknames need a human review, so they're now on the checklist above.
- **Force-pushing isn't the end on GitHub.** Pull request refs and cached commits keep old history reachable, so a full cleanup can mean recreating the repository (or asking GitHub Support).
- **Back up before rewriting history,** and check the result: the rewrite was confirmed by searching every commit and by comparing the final files byte for byte.
- **Other people's privacy counts too.** My friends didn't choose to be in my portfolio.
