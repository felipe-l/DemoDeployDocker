#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Load environment variables from the .env file
set -a
. ./.env
set +a

# Variables
DOMAIN_NAME=$DOMAIN_NAME
EMAIL=$EMAIL
APP_PORT=$APP_PORT

# Check if domain name, email, and app port are provided
if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL" ] || [ -z "$APP_PORT" ]; then
  echo "Please ensure DOMAIN, EMAIL, and APP_PORT are set in the .env file."
  exit 1
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
  echo "Nginx not found, installing..."
  apt update
  apt install -y nginx
fi

# Install Certbot if not installed
if ! command -v certbot &> /dev/null; then
  echo "Certbot not found, installing..."
  apt update
  apt install -y certbot python3-certbot-nginx
fi

# Create or update Nginx server block
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
echo "Creating or updating Nginx configuration for $DOMAIN_NAME..."
cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    location /api/ {
        proxy_pass http://localhost:$API_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable the site by creating a symlink
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t
if [ $? -ne 0 ]; then
  echo "Nginx configuration test failed. Exiting."
  exit 1
fi

# Reload Nginx to apply changes
systemctl reload nginx

# Obtain or renew SSL certificate
certbot --nginx -d "$DOMAIN_NAME" --email "$EMAIL" --agree-tos --non-interactive --redirect

echo "Nginx and SSL setup completed for $DOMAIN_NAME"