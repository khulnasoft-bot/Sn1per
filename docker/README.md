# Sn1per Docker Support

## Quick Start

```bash
# Build and run the CLI
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm sniper-cli -t example.com

# Start the API server
API_AUTH_TOKEN="your-secure-token" docker compose -f docker/docker-compose.yml up -d sniper-api
curl http://localhost:8080/v1/health

# With add-on services (MobSF, Redis)
docker compose -f docker/docker-compose.yml -f docker/docker-compose.addons.yml up -d
```

## Volumes

- `./loot` — Scan results persisted on host at `loot/`
- `./conf` — Read-only config overrides at `conf/`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `API_AUTH_TOKEN` | (none) | API authentication token |
| `API_PORT` | 8080 | API server port |
| `ADDON_*_ENABLED` | 1 | Per-add-on toggle (e.g. `ADDON_THREAT_INTEL_ENABLED=0`) |
