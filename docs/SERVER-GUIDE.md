# Art Marketplace — Server Connection & Commands Guide

## Server Info

| | |
|---|---|
| **Provider** | Hetzner CX23 |
| **IP** | 62.238.9.87 |
| **Location** | Helsinki |
| **Domain** | artmarketplace.duckdns.org |

## Subdomains

| Service | URL |
|---|---|
| Admin panel | https://admin-dev.artmarketplace.duckdns.org |
| Public app | https://app-dev.artmarketplace.duckdns.org |
| API backend | https://api-dev.artmarketplace.duckdns.org |
| API docs | https://api-dev.artmarketplace.duckdns.org/docs |
| Health check | https://api-dev.artmarketplace.duckdns.org/health |

## SSH Access

Two users on the server:

| User | Purpose | Prompt |
|---|---|---|
| `deploy` | Docker, git, deploy tasks | `$` |
| `root` | System-level tasks | `#` |

```bash
# Connect as deploy (most common):
ssh deploy@62.238.9.87

# Connect as root:
ssh root@62.238.9.87
```

SSH key on Windows: `C:\Users\user\.ssh\id_ed25519`

## GitHub Repos

| Repo | Purpose |
|---|---|
| [art-marketplace-api](https://github.com/art-marketplace-tm/art-marketplace-api) | FastAPI backend |
| [art-marketplace-admin](https://github.com/art-marketplace-tm/art-marketplace-admin) | Flutter admin panel |
| [art-marketplace-app](https://github.com/art-marketplace-tm/art-marketplace-app) | Flutter public app |
| [art-marketplace-infra](https://github.com/art-marketplace-tm/art-marketplace-infra) | Deployment config |

## Docker Containers

| Container | Service |
|---|---|
| `art-backend` | FastAPI API |
| `art-admin-panel` | Flutter admin (nginx) |
| `art-app-client` | Flutter public app (nginx) |
| `art-caddy` | Reverse proxy (TLS, routing) |
| `art-postgres` | Database |
| `art-redis` | Cache / Celery broker |
| `art-minio` | Object storage (images) |
| `art-celery-worker` | Background task runner |
| `art-celery-beat` | Scheduled tasks |

## Everyday Commands

```bash
# All running containers:
docker ps

# View logs:
docker logs art-backend --tail 100

# Follow logs live:
docker logs art-backend -f

# Restart single container:
docker restart art-backend

# Restart whole stack:
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml restart

# Server resources:
df -h
free -h
docker stats --no-stream
```

## Deploy

**Automatic:** Push to `dev` branch in any code repo auto-deploys that service only.

**Manual full redeploy:**
```bash
ssh deploy@62.238.9.87
bash ~/art-marketplace/scripts/deploy-dev.sh
```

**Manual single service:**
```bash
cd ~/art-marketplace
docker compose -f docker-compose.prod.yml pull backend
docker compose -f docker-compose.prod.yml up -d backend
```

## Database Access (DBeaver via SSH Tunnel)

**Main tab:** Host=localhost, Port=5433, Database=artmarket, User=artmarket, Password=see .env on server

**SSH tab:** Host=62.238.9.87, Port=22, User=deploy, Auth=Public Key, Key=C:\Users\user\.ssh\id_ed25519

## Admin User

```bash
docker exec art-backend python -m scripts.create_admin
```

## Editing .env on Server

```bash
cd ~/art-marketplace && nano .env
# After changes:
docker compose -f docker-compose.prod.yml up -d
```

## Troubleshooting

| Problem | Solution |
|---|---|
| Site is down | `docker ps` then `docker logs art-<name>` then `docker restart art-<name>` |
| Deploy failed | Check GitHub Actions in the respective repo |
| Out of disk | `docker system prune -a` |
| TLS cert error | `docker logs art-caddy --tail 50` |
