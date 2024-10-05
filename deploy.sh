#!/bin/bash
exec > /home/bitmap/logfile.log 2>&1

# Set variables
IMAGE_NAME="demo-nodejs-app-name"
CONTAINER_NAME="demo-nodejs-app-container"
DOCKERFILE_PATH="/home/bitmap/Projects/DemoDeployDocker/Dockerfile"
PORT=3000

# Stop and remove existing container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping and removing existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Build the new image
echo "Building new Docker image..."
docker build -t $IMAGE_NAME:latest -f $DOCKERFILE_PATH .
echo "FINISHED BUILDING!"

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# Run the new container
echo "Running new container..."
docker run -d --name $CONTAINER_NAME -p $PORT:$PORT $IMAGE_NAME:latest

# Check if container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container is running on port $PORT"
else
    echo "Failed to start container"
    exit 1
fi

echo "Script completed successfully"
