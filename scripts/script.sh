#!/bin/bash

# --- Install docker and docker-compose ---
apt-get update 
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update 
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y



# Add nginx for handling SSL
apt install certbot python3-certbot-nginx -y
cd /etc/nginx/
cd sites-available
echo "server {
    listen 80;
    server_name <domain-name>;

    # Increase upload size to unlimited
    client_max_body_size 0;

    location / {
        proxy_pass http://127.0.0.1:90;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;
        # Enables WS supportcd ..

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }
}" >> infisical
ln -s /etc/nginx/sites-available/infisical /etc/nginx/sites-enabled/
nginx -t

# --- docker compose infisical ---

# Change default 80 port to 90 (Due to ssl nginx, which is running on port 80).
cd /tmp
curl -o docker-compose.prod.yml https://raw.githubusercontent.com/Infisical/infisical/main/docker-compose.prod.yml
sed -i "s/ - 80:8080/ - 90:8080/" docker-compose.prod.yml

# Pull example .env file and change the default keys
curl -o .env https://raw.githubusercontent.com/Infisical/infisical/main/.env.example
randomEncryptionKey=`openssl rand -hex 16`
sed -i "/ENCRYPTION_KEY=/c ENCRYPTION_KEY=$randomEncryptionKey" .env
randomAuthSecret=`openssl rand -base64 32`
sed -i "/AUTH_SECRET=/c AUTH_SECRET=$randomAuthSecret" .env

docker compose -f /tmp/docker-compose.prod.yml up -d
