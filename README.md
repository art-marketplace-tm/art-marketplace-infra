# Art Marketplace — Infrastructure

Deployment and orchestration for the Art Marketplace platform.

## Architecture

```
                    ┌─────────────┐
                    │   Caddy     │ ← auto HTTPS (Let's Encrypt)
                    │  (reverse   │
                    │   proxy)    │
                    └──────┬──────┘
                           ▼
                    ┌────────────┐
                    │  Backend   │   ← Frontend (admin + public app)
                    │  (FastAPI) │     being migrated to Next.js;
                    │            │     containers will be added back
                    └─────┬──────┘     once the new stack is ready.
                          │
                    ┌─────┼─────────┐
                    ▼     ▼         ▼
                 ┌─────┐ ┌─────┐ ┌─────┐
                 │ PG  │ │Redis│ │MinIO│
                 └─────┘ └─────┘ └─────┘
```

All application containers are pre-built Docker images pulled from GitHub Container Registry (GHCR).
No source code lives on the server.

## Repos

| Repo | Purpose | Image |
|------|---------|-------|
| [art-marketplace-api](https://github.com/art-marketplace-tm/art-marketplace-api) | FastAPI backend | `ghcr.io/art-marketplace-tm/art-marketplace-api:dev` |
| **art-marketplace-infra** (this) | Deployment config | — |
| _Next.js admin & public app_ | _TBD — replacing the archived Flutter repos_ | _TBD_ |

## Quick start (server)

```bash
# First time:
bash scripts/setup-server.sh

# Regular deploy:
bash scripts/deploy-dev.sh

# Or manually:
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## Quick start (local development)

```bash
# Start only infrastructure (DB, Redis, MinIO):
cp .env.example .env
docker compose up -d

# Then run backend (and Next.js apps once they exist) locally — see their READMEs
```

## URLs

| Service | Dev URL |
|---------|---------|
| API | https://api-dev.artmarketplace.duckdns.org |
| API docs | https://api-dev.artmarketplace.duckdns.org/docs |
| Admin panel | _reserved: https://admin-dev.artmarketplace.duckdns.org (Next.js, not yet deployed)_ |
| Public app | _reserved: https://app-dev.artmarketplace.duckdns.org (Next.js, not yet deployed)_ |
