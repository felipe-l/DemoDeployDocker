#!/bin/bash

# Define variables
WEBHOOK_LISTENER_DIR="./webhook_listener"
APP_DEPLOY_DIR="./app_deploy"
WEBHOOK_CONTAINER_NAME="webhook_listener"
WEBHOOK_PORT=8080

# Step 1: Build and run the webhook listener
echo "Building and starting the webhook listener..."
cd "$WEBHOOK_LISTENER_DIR"
docker build -t $WEBHOOK_CONTAINER_NAME .

# Check if webhook listener container is already running and stop it if necessary
if [ "$(docker ps -q -f name=$WEBHOOK_CONTAINER_NAME)" ]; then
    echo "Stopping existing webhook listener container..."
    docker stop $WEBHOOK_CONTAINER_NAME
    docker rm $WEBHOOK_CONTAINER_NAME
fi

# Run the webhook listener container
docker run -d -p $WEBHOOK_PORT:8080 --name $WEBHOOK_CONTAINER_NAME $WEBHOOK_CONTAINER_NAME

# Check if webhook listener started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start webhook listener container. Exiting."
    exit 1
else
    echo "Webhook listener is running on port $WEBHOOK_PORT."
fi

# Step 2: Run the deploy script to start backend services
echo "Running deployment for backend..."
cd "../$APP_DEPLOY_DIR"
./deploy.sh

# Check if the deploy script ran successfully
if [ $? -ne 0 ]; then
    echo "Deployment failed. Exiting."
    exit 1
else
    echo "Deployment completed successfully."
fi
