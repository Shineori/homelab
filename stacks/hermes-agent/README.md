# Hermes Agent

Native systemd service on **ShineoriServer** (no Docker compose).

## Install

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
hermes setup
hermes model
```

## Model alias for local Ollama

```yaml
model:
  aliases:
    local-ollama:
      base_url: "http://localhost:11432/v1"
      provider: custom
```

Configure with `hermis config set` (see [docs/services/hermes-agent.md](../../docs/services/hermes-agent.md) for full setup notes).

## Run as a service

```bash
export HERMES_SERVICE=true
hermes install
systemctl --user enable --now hermes-agent.service
```

Logs: `~/.hermes/logs/`
Config: `~/.hermes/config.yaml`
Secrets: `~/.hermes/.env` (git-ignored)
