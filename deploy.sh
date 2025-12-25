#!/bin/bash
echo "🚀 Taksibu Backend Deployment Starting..."

# Detect Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Error: Docker Compose not found. Please install it first."
    exit 1
fi

echo "ℹ️ Using command: $COMPOSE_CMD"

# 1. Stop existing containers
echo "🛑 Stopping containers..."
$COMPOSE_CMD down

# 2. Build and Start
echo "🏗️ Building and Starting..."
$COMPOSE_CMD up -d --build

# 3. Cleanup unused images
echo "🧹 Cleaning up..."
docker image prune -f

echo "✅ Deployment Complete! Server running on Port 3000."
$COMPOSE_CMD ps
