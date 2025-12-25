#!/bin/bash
echo "🚀 Taksibu Backend Deployment Starting..."

# 1. Stop existing containers
echo "🛑 Stopping containers..."
docker-compose down

# 2. Build and Start
echo "🏗️ Building and Starting..."
docker-compose up -d --build

# 3. Cleanup unused images
echo "🧹 Cleaning up..."
docker image prune -f

echo "✅ Deployment Complete! Server running on Port 3000."
docker-compose ps
