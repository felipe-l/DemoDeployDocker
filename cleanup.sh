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

# Remove cron job responsible for executing deploy.sh and stop any current instance
./clean_up_cron_job.sh

# Step 2: Stop and remove all backend services in app_deploy
echo "Stopping and removing backend services..."
for dir in "$(dirname "$0")"/app_deploy/*; do
    if [ -d "$dir" ] && [ -f "$dir/docker-compose.yml" ]; then
        echo "Stopping and removing services in $dir..."
        cd "$dir" || { echo "Failed to navigate to $dir"; exit 1; }
        docker compose down --volumes
        echo "Backend services in $dir removed."
        cd ..  # Navigate back to app_deploy directory
    fi
done

# Step 3: Remove any dangling images or unused volumes
echo "Removing dangling images and unused volumes..."
docker image prune -f
docker volume prune -f
echo "Cleanup completed."

# Step 4: Navigate back to the original directory (if needed)
cd ..

echo "All containers and resources cleaned up."
