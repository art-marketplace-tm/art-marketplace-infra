# Art Marketplace — Infrastructure

## What is this
Infrastructure and deployment configuration for the Art Marketplace platform.
This repo is cloned on the production/dev server and orchestrates all services.

## Related repos (all under art-marketplace-tm org)
- **art-marketplace-api** — FastAPI backend → `ghcr.io/art-marketplace-tm/art-marketplace-api:dev`
- _Frontend (admin + public app) is being migrated to Next.js. The old Flutter repos are archived; new repo names TBD._

## What's in this repo
```
├── docker-compose.prod.yml   # Production: pulls pre-built GHCR images
├── docker-compose.yml        # Local dev: just Postgres + Redis + MinIO
├── Caddyfile                 # Reverse proxy config (auto HTTPS)
├── .env.example              # Local dev env template
├── .env.dev.example          # Dev server env template (DuckDNS)
├── .env.prod.example         # Production env template
├── scripts/
│   ├── deploy-dev.sh         # Pull images + restart + migrate
│   └── setup-server.sh       # First-time server setup
└── docs/
    └── ARCHITECTURE.md       # Full architecture documentation
```

## How deployment works
Each code repo has its own GitHub Actions workflow:
1. Developer pushes to `dev` branch
2. GitHub Actions builds Docker image
3. Image pushed to GHCR (ghcr.io/art-marketplace-tm/...)
4. SSH into server → pull image → restart service
5. No source code on the server — only this infra repo + .env

## Server info
- **Host:** Hetzner CX23 — 62.238.9.87 (Helsinki)
- **Domain:** artmarketplace.duckdns.org
- **Users:** `root` (system), `deploy` (docker/git)
- **Path:** `/home/deploy/art-marketplace/` (this repo)

## Subdomains
- https://api-dev.artmarketplace.duckdns.org — API + docs
- `admin-dev.*` and `app-dev.*` are reserved for the new Next.js stack (currently no service bound)

## Common operations
```bash
# SSH to server:
ssh deploy@62.238.9.87

# Full redeploy:
bash ~/art-marketplace/scripts/deploy-dev.sh

# View logs:
docker logs art-backend --tail 100

# Restart single service:
docker restart art-backend

# DB access (from server):
docker compose -f docker-compose.prod.yml exec postgres psql -U artmarket

# Create admin user:
docker compose -f docker-compose.prod.yml exec backend python -m scripts.create_admin
```

## Environment files
- `.env` on server contains all secrets (NOT in git)
- `.env.example` — local development template
- `.env.dev.example` — dev server template (Hetzner + DuckDNS)
- `.env.prod.example` — production template (real domain)
