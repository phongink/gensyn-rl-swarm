#!/bin/bash

set -e

APT_OPTIONS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

echo "Starting the automatic installation and environment setup process..."
echo "This process will run completely non-interactively."
echo ""

echo "PART 1: Recreating 32GB swap file..."
sudo swapoff -a && if [ -f /swapfile ]; then sudo rm /swapfile; fi
sudo fallocate -l 32G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
if ! grep -q "/swapfile" /etc/fstab; then echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab; fi
echo "--- PART 1 COMPLETE ---" && echo ""

echo "PART 2: Updating the system..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS upgrade
echo "--- PART 2 COMPLETE ---" && echo ""

echo "PART 3: Installing essential packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip python3-venv python3-dev
echo "--- PART 3 COMPLETE ---" && echo ""

echo "PART 4: Installing Node.js v22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install nodejs
echo "--- PART 4 COMPLETE ---" && echo ""

echo "PART 5: Installing Yarn Berry and configuring PATH..."
curl -o- -L https://yarnpkg.com/install.sh | bash
YARN_PATH_EXPORT='export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"'
if ! grep -qF -- "$YARN_PATH_EXPORT" ~/.bashrc; then echo -e "\n# YARN PATH CONFIGURATION\n$YARN_PATH_EXPORT" >> ~/.bashrc; fi
echo "--- PART 5 COMPLETE ---" && echo ""

echo "PART 6: Cloning the rl-swarm source code..."
cd "$HOME"
if [ ! -d "rl-swarm" ]; then git clone https://github.com/gensyn-ai/rl-swarm/; fi
echo "--- PART 6 COMPLETE ---" && echo ""

echo "PART 7: Installing Docker Engine..."
sudo apt-get update
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y $pkg || true; done
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /etc/apt/sources.list.d
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd -f docker
sudo usermod -aG docker $USER
echo "--- PART 7 COMPLETE ---" && echo ""

echo "Installation complete! Transferring to 'screen' session and launching the application..."
echo "You will see the application output immediately."
echo ""

COMMAND_TO_RUN="cd $HOME/rl-swarm && sudo docker compose run --rm --build -Pit swarm-cpu"

exec screen -S swarm bash -c "$COMMAND_TO_RUN"
