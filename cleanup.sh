#!/bin/bash

# Load environment variables from the .env file
set -a  # Automatically export all variables
source ./app_deploy/.env
set +a  # Stop exporting

# Step 1: Stop and remove the webhook listener container
echo "Stopping and removing the webhook listener container..."
if [ "$(docker ps -q -f name=$WEBHOOK_CONTAINER_NAME)" ]; then
    docker stop $WEBHOOK_CONTAINER_NAME
    docker rm $WEBHOOK_CONTAINER_NAME
    echo "Webhook listener container removed."
else
    echo "No running webhook listener container found."
fi

# Step 2: Stop and remove all backend services
echo "Stopping and removing backend services..."
cd "./app_deploy"
docker compose down --volumes
echo "Backend services removed."

# Step 3: Remove any dangling images or unused volumes
echo "Removing dangling images and unused volumes..."
docker image prune -f
docker volume prune -f
echo "Cleanup completed."

# Step 4: Navigate back to the original directory
cd ..

echo "All containers and resources cleaned up."
