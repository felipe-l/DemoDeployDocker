#!/bin/bash

echo "Setting executable permissions for scripts..."
chmod +x ./cleanup.sh
chmod +x ./add_cron_job.sh
chmod +x ./clean_up_cron_job.sh
chmod +x ./app_deploy/deploy.sh  # Assuming deploy.sh is inside the app_deploy directory
chmod +x ./setup_nginx_ssl.sh  # Ensure setup_nginx_ssl.sh is executable

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

# Check if named pipe exists, if not create it
PIPE_PATH="$(dirname "$0")/pipe/mypipe"  # Update this to match the location of your pipe

if [ ! -p "$PIPE_PATH" ]; then
    mkfifo "$PIPE_PATH"
    echo "Created named pipe at $PIPE_PATH"
else
    echo "Named pipe already exists at $PIPE_PATH"
fi

echo "setting cron job"
./add_cron_job.sh

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

docker run -d -p "$WEBHOOK_PORT:8080" \
    --name "$WEBHOOK_CONTAINER_NAME" \
    -v "$(pwd)/../pipe:/hostpipe" \
    --env-file ./../.env \
    "$WEBHOOK_CONTAINER_NAME"

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

cd ..
if [ "$SETUP_SSL" = true ]; then
    echo "Setting up SSL..."
    ./setup_nginx_ssl.sh
fi

# Check if the deploy script ran successfully
if [ $? -ne 0 ]; then
    echo "Deployment failed. Exiting."
    exit 1
else
    echo "Deployment completed successfully."
fi
