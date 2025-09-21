#!/usr/bin/env bash

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
    tzdata \
    gcc g++ gfortran


# ------------------------------------------------------------------------------
# Azure CLI (Pinned 12.5.0)
# ------------------------------------------------------------------------------
echo ">>> Installing Azure CLI 12.5.0..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version


# ------------------------------------------------------------------------------
# AzCopy (v10.x)
# ------------------------------------------------------------------------------
echo ">>> Installing AzCopy..."
AZCOPY_VERSION="10.25.1"
wget -q https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz
tar -xvf azcopy.tar.gz
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/local/bin/
rm -rf azcopy*


# ------------------------------------------------------------------------------
# Apache (latest Ubuntu repo)
# ------------------------------------------------------------------------------
echo ">>> Installing Apache2..."
sudo apt-get install -y apache2
sudo systemctl disable apache2 || true


# ------------------------------------------------------------------------------
# CMake
# ------------------------------------------------------------------------------
echo ">>> Installing CMake 3.31.5..."
CMAKE_VERSION=3.31.5
wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh
sudo mkdir -p /opt/cmake/${CMAKE_VERSION}
sudo sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --skip-license --prefix=/opt/cmake/${CMAKE_VERSION}
sudo ln -sf /opt/cmake/${CMAKE_VERSION}/bin/* /usr/local/bin/
rm cmake-${CMAKE_VERSION}-linux-x86_64.sh


# ------------------------------------------------------------------------------
# .NET SDK
# ------------------------------------------------------------------------------
echo ">>> Installing .NET SDK 8.0 and 9.0..."
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install -y dotnet-sdk-8.0 dotnet-sdk-9.0
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$DOTNET_ROOT:$PATH


# ------------------------------------------------------------------------------
# Java Tools (JDKs + Maven + Gradle)
# ------------------------------------------------------------------------------
echo ">>> Installing Java JDKs and build tools..."
sudo apt-get install -y openjdk-8-jdk openjdk-11-jdk openjdk-17-jdk openjdk-21-jdk
sudo apt-get install -y maven gradle
export JAVA_HOME_8=/usr/lib/jvm/java-8-openjdk-amd64
export JAVA_HOME_11=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA_HOME_17=/usr/lib/jvm/java-17-openjdk-amd64
export JAVA_HOME_21=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME_17/bin:$PATH


# ------------------------------------------------------------------------------
# GitHub CLI
# ------------------------------------------------------------------------------
echo ">>> Installing GitHub CLI..."
type -p curl >/dev/null || (sudo apt-get update -y && sudo apt-get install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update -y
sudo apt-get install gh -y


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

echo ">>> Installed Python versions:"
for version in "${PYTHON_VERSIONS[@]}"; do
    short="${version%.*}"
    echo -n "Python $version: "
    /usr/bin/python${short} --version || true
done


# ------------------------------------------------------------------------------
# Kubernetes tools (kubectl, helm, kustomize)
# ------------------------------------------------------------------------------
echo ">>> Installing Kubernetes tools..."
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# kustomize
KUSTOMIZE_VERSION=v5.4.2
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/


# ------------------------------------------------------------------------------
# SBT (Scala build tool)
# ------------------------------------------------------------------------------
echo ">>> Installing SBT..."
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install sbt -y


# ------------------------------------------------------------------------------
# vcpkg
# ------------------------------------------------------------------------------
echo ">>> Installing vcpkg..."
git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg
/opt/vcpkg/bootstrap-vcpkg.sh -disableMetrics
export VCPKG_ROOT=/opt/vcpkg
export PATH=$VCPKG_ROOT:$PATH


# ------------------------------------------------------------------------------
# yq
# ------------------------------------------------------------------------------
echo ">>> Installing yq v4..."
YQ_VERSION=v4.44.3
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O yq
chmod +x yq
sudo mv yq /usr/local/bin/


# ------------------------------------------------------------------------------
# Docker (Pinned 28.0.4 + Compose 2.38.2)
# ------------------------------------------------------------------------------
echo ">>> Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce=5:28.0.4-1~ubuntu.22.04~jammy docker-ce-cli=5:28.0.4-1~ubuntu.22.04~jammy containerd.io docker-buildx-plugin docker-compose-plugin=2.38.2-1~ubuntu.22.04~jammy
sudo usermod -aG docker $USER


# ------------------------------------------------------------------------------
# Pipx
# ------------------------------------------------------------------------------
echo ">>> Installing pipx..."
sudo apt-get install -y pipx python3-venv
pipx ensurepath


# ------------------------------------------------------------------------------
# Container tools (latest podman, buildah, skopeo)
# ------------------------------------------------------------------------------
echo ">>> Installing container tools..."
sudo apt-get install -y podman buildah skopeo


# ------------------------------------------------------------------------------
# Call PowerShell module installer
# ------------------------------------------------------------------------------
echo ">>> Installing PowerShell modules..."
sudo pwsh -File /imagegeneration/install-powershell-modules.ps1


# ------------------------------------------------------------------------------
# Toolset (JSON definition)
# ------------------------------------------------------------------------------
echo ">>> Installing toolset config..."
sudo mkdir -p /imagegeneration
wget -q https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/toolsets/toolset-2204.json -O /imagegeneration/toolset.json


# ------------------------------------------------------------------------------
# DPKG Fix
# ------------------------------------------------------------------------------
echo ">>> Running dpkg fix..."
sudo dpkg --configure -a


# ------------------------------------------------------------------------------
# Toolset & Toolcache Finalization
# ------------------------------------------------------------------------------
echo ">>> Creating toolcache directories..."
sudo mkdir -p /opt/hostedtoolcache/{Python,go,Node,Ruby,Java} /imagegeneration
sudo chmod -R 0777 /opt/hostedtoolcache

cat << 'EOF' | sudo tee -a /etc/environment
DOTNET_ROOT=/usr/share/dotnet
JAVA_HOME_8=/usr/lib/jvm/java-8-openjdk-amd64
JAVA_HOME_11=/usr/lib/jvm/java-11-openjdk-amd64
JAVA_HOME_17=/usr/lib/jvm/java-17-openjdk-amd64
JAVA_HOME_21=/usr/lib/jvm/java-21-openjdk-amd64
VCPKG_ROOT=/opt/vcpkg
AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
PATH="$PATH:/usr/share/dotnet:/opt/vcpkg:/opt/vcpkg/bin:/opt/hostedtoolcache"
EOF


# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------

docker --version
docker compose version
kubectl version --client --output=yaml
helm version
az version

echo ">>> Bootstrap completed."
echo ">>> IMPORTANT: Log out and log back in (or restart) so Docker group membership takes effect."
