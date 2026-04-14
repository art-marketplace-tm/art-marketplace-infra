# Server Migration Guide: Monorepo to Multi-Repo

This guide covers migrating the Hetzner dev server from the old monorepo
setup to the new multi-repo architecture with GHCR images.

## Prerequisites

- SSH access to `deploy@62.238.9.87`
- A GitHub Personal Access Token (PAT) with `read:packages` scope
  - Create at: https://github.com/settings/tokens/new?scopes=read:packages

## Migration Steps

### 1. SSH into the server

```bash
ssh deploy@62.238.9.87
```

### 2. Back up the current .env

```bash
cp ~/art-marketplace/.env ~/art-marketplace-env-backup
```

### 3. Stop the current stack

```bash
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml down
```

### 4. Remove old source code, keep data

```bash
mv ~/art-marketplace ~/art-marketplace-old
```

### 5. Clone the infra repo

```bash
git clone https://github.com/art-marketplace-tm/art-marketplace-infra.git ~/art-marketplace
cd ~/art-marketplace
git checkout dev
```

### 6. Restore .env

```bash
cp ~/art-marketplace-env-backup ~/art-marketplace/.env
```

### 7. Log in to GitHub Container Registry

```bash
echo "YOUR_GITHUB_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

Replace `YOUR_GITHUB_PAT` with your actual PAT and `YOUR_GITHUB_USERNAME` with your GitHub username.

### 8. Pull all images and start

```bash
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### 9. Run migrations and verify

```bash
docker compose -f docker-compose.prod.yml exec -T backend alembic upgrade head
curl -sf https://api-dev.artmarketplace.duckdns.org/health
docker ps
```

### 10. Verify in browser

- https://admin-dev.artmarketplace.duckdns.org
- https://app-dev.artmarketplace.duckdns.org
- https://api-dev.artmarketplace.duckdns.org/docs

### 11. Clean up (after verifying)

```bash
rm -rf ~/art-marketplace-old
docker image prune -a -f
```

## Rollback

```bash
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml down
mv ~/art-marketplace ~/art-marketplace-new
mv ~/art-marketplace-old ~/art-marketplace
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml up -d --build
```

## What Changed

| Before (monorepo) | After (multi-repo) |
|---|---|
| Full source code on server | Only infra config on server |
| `docker compose build` compiles on server | `docker compose pull` downloads pre-built images |
| Flutter builds on server (15-30 min) | Flutter builds on GitHub CI (free) |
| One deploy = everything restarts | Each service deploys independently |
| Push to `dev` in monorepo | Push to `dev` in respective repo |
