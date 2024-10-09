#!/bin/bash
exec > "$(dirname "$0")/logfile.log" 2>&1  # Log file in the current directory

echo "HERE!"
# Load environment variables from the .env file
set -a  # Automatically export all variables
. ../.env
set +a  # Stop exporting

# Set up variables from the .env file
REPO_URL="${REPO_URL}"
REPO_NAME=$(basename -s .git "$REPO_URL")  # Extract repo name from URL
APP_BASE_DIR="$(dirname "$0")"
APP_DIR="$APP_BASE_DIR/$REPO_NAME"  # Target directory for the repo
DOCKER_COMPOSE_PATH="$APP_DIR/docker-compose.yml"

# Ensure that REPO_URL is set
if [ -z "$REPO_URL" ]; then
    echo "REPO_URL is not set in the environment. Exiting."
    exit 1
fi

# Look for any existing repositories in app_deploy
for DIR in "$APP_BASE_DIR"/*; do
    if [ -d "$DIR/.git" ]; then
        EXISTING_REPO_URL=$(git -C "$DIR" config --get remote.origin.url)
        
        if [ "$EXISTING_REPO_URL" != "$REPO_URL" ]; then
            echo "$EXISTING_REPO_URL different from $REPO_URL"
            # Delete the directory if the URLs do not match
            echo "Different repository detected at $DIR. Deleting it..."
            rm -rf "$DIR"
        else
            # Repo matches; we should just pull the latest changes
            echo "Repository matches at $DIR. Pulling latest changes..."
            cd "$DIR"
            git fetch origin main
            git reset --hard origin/main
            if [ $? -ne 0 ]; then
                echo "Git pull failed. Exiting."
                exit 1
            fi
            # Set APP_DIR to the matched repo directory
            APP_DIR="$DIR"
        fi
    fi
done

# Clone the repository if it doesn't exist
if [ ! -d "$APP_DIR" ]; then
    echo "Cloning repository from $REPO_URL into $APP_DIR..."
    cd "$APP_BASE_DIR"
    git clone "$REPO_URL" "$APP_DIR"
    git config --global --add safe.directory "$APP_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to clone repository. Exiting."
        exit 1
    fi
fi

# Stop and remove existing Docker containers
echo "Stopping and removing existing Docker Compose containers..."
docker compose -f "$DOCKER_COMPOSE_PATH" down

# Rebuild and run the Docker Compose services
echo "Building and running Docker Compose services..."
docker compose -f "$DOCKER_COMPOSE_PATH" up --build -d

if [ $? -ne 0 ]; then
    echo "Docker Compose failed to start services. Exiting."
    exit 1
fi

echo "Deployment completed successfully."
