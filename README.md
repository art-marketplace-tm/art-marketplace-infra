# Art Marketplace — Infrastructure

Deployment and orchestration for the Art Marketplace platform.

## Architecture

```
                    ┌─────────────┐
                    │   Caddy     │ ← auto HTTPS (Let's Encrypt)
                    │  (reverse   │
                    │   proxy)    │
                    └──────┬──────┘
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌────────────┐ ┌──────────┐ ┌──────────┐
     │  Backend   │ │  Admin   │ │   App    │
     │  (FastAPI) │ │ (Flutter │ │ (Flutter │
     │            │ │   nginx) │ │   nginx) │
     └─────┬──────┘ └──────────┘ └──────────┘
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
| [art-marketplace-admin](https://github.com/art-marketplace-tm/art-marketplace-admin) | Admin dashboard | `ghcr.io/art-marketplace-tm/art-marketplace-admin:dev` |
| [art-marketplace-app](https://github.com/art-marketplace-tm/art-marketplace-app) | Public app | `ghcr.io/art-marketplace-tm/art-marketplace-app:dev` |
| **art-marketplace-infra** (this) | Deployment config | — |

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

# Then run backend + Flutter apps locally (see their READMEs)
```

## URLs

| Service | Dev URL |
|---------|---------|
| Admin panel | https://admin-dev.artmarketplace.duckdns.org |
| Public app | https://app-dev.artmarketplace.duckdns.org |
| API | https://api-dev.artmarketplace.duckdns.org |
| API docs | https://api-dev.artmarketplace.duckdns.org/docs |
