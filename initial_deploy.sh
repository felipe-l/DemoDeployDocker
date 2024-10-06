#!/bin/bash

# Load environment variables from the .env file
set -a  # Automatically export all variables
. ./.env  # Use dot instead of source
set +a  # Stop exporting

# Call the cleanup script to remove any previous instances
echo "Running cleanup before deployment..."
./cleanup.sh

# Debugging: Print loaded variables
echo "Loaded variables:"
echo "WEBHOOK_LISTENER_DIR: $WEBHOOK_LISTENER_DIR"
echo "APP_DEPLOY_DIR: $APP_DEPLOY_DIR"
echo "WEBHOOK_CONTAINER_NAME: $WEBHOOK_CONTAINER_NAME"
echo "WEBHOOK_PORT: $WEBHOOK_PORT"

# Step 1: Build and run the webhook listener
echo "Building and starting the webhook listener..."
cd "$WEBHOOK_LISTENER_DIR" || { echo "Directory not found: $WEBHOOK_LISTENER_DIR"; exit 1; }
docker build -t "$WEBHOOK_CONTAINER_NAME" .

# Check if webhook listener container is already running and stop it if necessary
if [ "$(docker ps -q -f name=$WEBHOOK_CONTAINER_NAME)" ]; then
    echo "Stopping existing webhook listener container..."
    docker stop "$WEBHOOK_CONTAINER_NAME"
    docker rm "$WEBHOOK_CONTAINER_NAME"
fi

# Run the webhook listener container
docker run -d -p "$WEBHOOK_PORT:8080" --name "$WEBHOOK_CONTAINER_NAME" "$WEBHOOK_CONTAINER_NAME"

# Check if webhook listener started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start webhook listener container. Exiting."
    exit 1
else
    echo "Webhook listener is running on port $WEBHOOK_PORT."
fi

# Step 2: Run the deploy script to start backend services
echo "Running deployment for backend..."
cd "../$APP_DEPLOY_DIR" || { echo "Directory not found: $APP_DEPLOY_DIR"; exit 1; }
./deploy.sh

# Check if the deploy script ran successfully
if [ $? -ne 0 ]; then
    echo "Deployment failed. Exiting."
    exit 1
else
    echo "Deployment completed successfully."
fi
