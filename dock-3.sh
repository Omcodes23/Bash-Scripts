#!/bin/bash

set -e

echo "[+] Updating system..."
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "[+] Setting up Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "[+] Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[+] Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[+] Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Docker installed successfully!"

# ========== Install Portainer ==========
echo "[+] Setting up Portainer..."
sudo docker volume create portainer_data
sudo docker run -d \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce

# ========== Install Dockage ==========
echo "[+] Setting up Dockage..."
sudo docker run -d \
  -p 5000:5000 \
  --name dockage \
  --restart always \
  liranpa/dockage

echo ""
echo "[✔] Setup complete!"
echo "→ Portainer: http://localhost:9000"
echo "→ Dockage:   http://localhost:5000"
