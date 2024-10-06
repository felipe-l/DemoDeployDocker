#!/bin/bash

# Load environment variables from the .env file
set -a  # Automatically export all variables
. ./.env
set +a  # Stop exporting

# Step 1: Stop and remove the webhook listener container
echo "Stopping and removing the webhook listener container..."
if [ "$(docker ps -q -f name=$WEBHOOK_CONTAINER_NAME)" ]; then
    # Attempt to stop the container
    docker stop "$WEBHOOK_CONTAINER_NAME"
    if [ $? -eq 0 ]; then
        echo "Webhook listener container stopped."
    else
        echo "Failed to stop the webhook listener container, trying to force stop."
        docker rm -f "$WEBHOOK_CONTAINER_NAME"  # Force remove if stop fails
        echo "Webhook listener container forced removed."
        exit 1
    fi

    # Attempt to remove the container
    docker rm "$WEBHOOK_CONTAINER_NAME"
    if [ $? -eq 0 ]; then
        echo "Webhook listener container removed."
    else
        echo "Failed to remove the webhook listener container, trying to force remove."
        docker rm -f "$WEBHOOK_CONTAINER_NAME"  # Force remove if rm fails
        echo "Webhook listener container forced removed."
    fi
else
    echo "No running webhook listener container found."
fi

# Step 2: Stop and remove all backend services
echo "Stopping and removing backend services..."
cd "$APP_DEPLOY_DIR" || { echo "Directory not found: $APP_DEPLOY_DIR"; exit 1; }
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
