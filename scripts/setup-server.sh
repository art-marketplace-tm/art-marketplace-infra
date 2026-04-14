#!/usr/bin/env bash
set -euo pipefail

# First-time server setup for Art Marketplace
# Run as: deploy user on the Hetzner box

echo "=== Art Marketplace Server Setup ==="

INSTALL_DIR=~/art-marketplace

# Clone infra repo
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Cloning infra repo..."
  git clone https://github.com/art-marketplace-tm/art-marketplace-infra.git "$INSTALL_DIR"
else
  echo "Directory exists, pulling latest..."
  cd "$INSTALL_DIR" && git pull
fi

cd "$INSTALL_DIR"

# Check .env exists
if [ ! -f .env ]; then
  echo ""
  echo "ERROR: .env file not found!"
  echo "Copy .env.dev.example to .env and fill in the values:"
  echo "  cp .env.dev.example .env"
  echo "  nano .env"
  echo ""
  exit 1
fi

# Login to GHCR (needed to pull private images)
echo ""
echo "Logging in to GitHub Container Registry..."
echo "You need a GitHub PAT with read:packages scope."
echo "Create one at: https://github.com/settings/tokens/new?scopes=read:packages"
echo ""
read -p "Enter your GitHub username: " GH_USER
read -sp "Enter your GitHub PAT: " GH_TOKEN
echo ""
echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin

# Pull and start everything
echo ""
echo "=== Pulling images ==="
docker compose -f docker-compose.prod.yml pull

echo ""
echo "=== Starting services ==="
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "=== Waiting for database ==="
sleep 5

echo ""
echo "=== Running migrations ==="
docker compose -f docker-compose.prod.yml exec -T backend alembic upgrade head

echo ""
echo "=== Creating admin user ==="
docker compose -f docker-compose.prod.yml exec -T backend python -m scripts.create_admin

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Services:"
docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""
echo "URLs:"
echo "  Admin:  https://admin-dev.artmarketplace.duckdns.org"
echo "  App:    https://app-dev.artmarketplace.duckdns.org"
echo "  API:    https://api-dev.artmarketplace.duckdns.org"
echo "  Docs:   https://api-dev.artmarketplace.duckdns.org/docs"
