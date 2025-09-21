#!/usr/bin/env bash
set -euo pipefail

echo ">>> Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo ">>> Installing common utilities..."
sudo apt-get install -y \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl \
    wget \
    unzip \
    jq \
    git \
    lsb-release

# ------------------------------------------------------------------------------
# Python Setup (toolcache for UsePythonVersion@0)
# ------------------------------------------------------------------------------
echo ">>> Installing multiple Python versions (3.8, 3.9, 3.10, 3.11)..."

sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -y

PYTHON_VERSIONS=("3.8.18" "3.9.18" "3.10.13" "3.11.6")

for version in "${PYTHON_VERSIONS[@]}"; do
    short="${version%.*}"   # e.g. 3.11.6 -> 3.11

    echo ">>> Installing Python $version ..."
    sudo apt-get install -y python${short} python${short}-dev python${short}-distutils

    TOOLCACHE=/opt/hostedtoolcache/Python/$version/x64
    sudo mkdir -p $TOOLCACHE/bin

    # Symlink into toolcache
    sudo ln -sf /usr/bin/python${short} $TOOLCACHE/bin/python
    sudo ln -sf /usr/bin/python${short} $TOOLCACHE/bin/python3

    # Mark as complete so UsePythonVersion@0 recognizes it
    sudo touch $TOOLCACHE.complete
done

# ------------------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------------------
echo ">>> Installing Docker..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Adding current user to docker group..."
sudo usermod -aG docker $USER

# ------------------------------------------------------------------------------
# kubectl
# ------------------------------------------------------------------------------
echo ">>> Installing kubectl (latest stable)..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# ------------------------------------------------------------------------------
# Helm
# ------------------------------------------------------------------------------
echo ">>> Installing Helm (latest stable)..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ------------------------------------------------------------------------------
# Azure CLI
# ------------------------------------------------------------------------------
echo ">>> Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
echo ">>> Installed versions:"
for version in "${PYTHON_VERSIONS[@]}"; do
    short="${version%.*}"
    echo -n "Python $version: "
    /usr/bin/python${short} --version || true
done

docker --version
docker compose version
kubectl version --client --output=yaml
helm version
az version

echo ">>> Bootstrap completed."
echo ">>> IMPORTANT: Log out and log back in (or restart) so Docker group membership takes effect."
