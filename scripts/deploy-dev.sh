#!/usr/bin/env bash
set -euo pipefail

cd ~/art-marketplace

echo "=== Pulling latest images ==="
docker compose -f docker-compose.prod.yml pull backend celery-worker celery-beat

echo "=== Restarting services ==="
docker compose -f docker-compose.prod.yml up -d

echo "=== Running migrations ==="
docker compose -f docker-compose.prod.yml exec -T backend alembic upgrade head

echo "=== Health check ==="
for i in $(seq 1 30); do
  if docker compose -f docker-compose.prod.yml exec -T backend curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo "Backend is healthy!"
    break
  fi
  echo "Waiting for backend... ($i/30)"
  sleep 2
done

echo "=== Cleaning up old images ==="
docker image prune -f

echo "=== Current status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "=== Deploy complete ==="
