# Excalidraw stack

Write-up: [docs/services/excalidraw.md](../../docs/services/excalidraw.md)

## Build and run

```bash
git clone --depth 1 --branch v0.28.0 https://github.com/kitsteam/excalidraw src
cp -r shineori src/
echo '!shineori/' >> src/.dockerignore      # the fork's .dockerignore is a whitelist
# edit src/shineori/env.production: replace draw.example.com with your hostname
cp .env.example .env && chmod 600 .env       # fill it in
docker compose build excalidraw
docker compose up -d
```

`src/` and `data/` are not in this repo. Changing the domain means editing `env.production` and rebuilding.
