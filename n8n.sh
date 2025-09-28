#!/bin/bash

# Script to install n8n with all dependencies on Ubuntu 24.04+
# Usage: sudo bash install_n8n.sh

echo "==== n8n Installation Script ===="

# Prompt user for hostname and IP
read -p "Enter the workflow hostname (e.g., workflow.example.com): " WORKFLOW_HOST
read -p "Enter the server IP address (e.g., 80.225.197.98): " SERVER_IP

echo ""
echo "Please ensure that the DNS A record for $WORKFLOW_HOST points to $SERVER_IP."
echo "Otherwise, SSL certificate issuance will fail!"
echo ""
read -p "Have you updated the DNS A record? (y/n): " DNS_CONFIRM

if [[ "$DNS_CONFIRM" != "y" ]]; then
    echo "Please update your DNS record before proceeding."
    exit 1
fi

echo "Proceeding with installation..."

# Step 1: Update & install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt-get install vim zip dnsutils ufw docker.io docker-compose nginx certbot python3-certbot-nginx -y

# Step 2: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Step 3: Set docker permissions and start
sudo chmod 777 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker

# Step 4: Firewall configuration
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
sudo ufw allow 5678/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Step 5: Setup n8n container
mkdir -p ~/n8n && cd ~/n8n

docker run -d --restart unless-stopped -it \
--name n8n \
-p 5678:5678 \
-e N8N_HOST="$WORKFLOW_HOST" \
-e WEBHOOK_TUNNEL_URL="$WORKFLOW_HOST" \
-e WEBHOOK_URL="$WORKFLOW_HOST/" \
-v ~/.n8n:/root/.n8n \
n8nio/n8n

docker ps

# Step 6: Nginx configuration for reverse proxy
NGINX_CONF="/etc/nginx/sites-available/n8n"
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $WORKFLOW_HOST;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }

    location / {
        proxy_pass http://localhost:5678/;
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Step 7: Obtain SSL certificate using Certbot
sudo certbot --nginx -d $WORKFLOW_HOST

echo ""
echo "==== Installation Complete! ===="
echo "n8n is running behind Nginx reverse proxy at https://${WORKFLOW_HOST}"
echo ""
echo "SSL Certificate is saved at: /etc/letsencrypt/live/${WORKFLOW_HOST}/fullchain.pem"
echo "Key is saved at: /etc/letsencrypt/live/${WORKFLOW_HOST}/privkey.pem"
echo ""
echo "If you change your domain or IP, update DNS records and re-run certbot."
