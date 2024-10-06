#!/bin/bash
exec > "$(dirname "$0")/logfile.log" 2>&1  # Log file in the current directory

# Load environment variables from the .env file
set -a  # Automatically export all variables
. ../.env
set +a  # Stop exporting

# Navigate to the app_deploy directory
cd "$(dirname "$0")"

# Define the Docker Compose path
DOCKER_COMPOSE_PATH="./docker-compose.yml"

# Pull the latest changes only for the app_deploy directory
echo "Pulling latest changes for app_deploy from GitHub..."
git fetch origin main
git checkout origin/main -- .

if [ $? -ne 0 ]; then
    echo "Git pull failed. Exiting."
    exit 1
fi

# Stop and remove existing Docker containers
echo "Stopping and removing existing Docker Compose containers..."
docker compose -f $DOCKER_COMPOSE_PATH down

# Rebuild and run the Docker Compose services with the specified port
echo "Building and running Docker Compose services on port ${BACKEND_PORT}..."
docker compose -f $DOCKER_COMPOSE_PATH up --build -d

if [ $? -ne 0 ]; then
    echo "Docker Compose failed to start services. Exiting."
    exit 1
fi

echo "Deployment completed successfully on port ${BACKEND_PORT}."
