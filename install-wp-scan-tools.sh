#!/bin/bash

# Installation script for WordPress vulnerability scanner tools on Kali Linux
# Version: 1.1 - Removed wordlist installation
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log functions
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warning_log() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error_log() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error_log "This script must be run as root (use sudo)"
fi

# Update system
log "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install base dependencies
log "Installing base dependencies..."
apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    ruby \
    ruby-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    build-essential \
    unzip \
    wget \
    jq \
    nmap \
    sslscan

# Install Go
log "Installing Go..."
if ! command -v go >/dev/null 2>&1; then
    wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export GOPATH=$HOME/go' >> /etc/profile
    source /etc/profile
    rm go1.23.0.linux-amd64.tar.gz
else
    log "Go is already installed"
fi

# Install WPScan
log "Installing WPScan..."
if ! command -v wpscan >/dev/null 2>&1; then
    gem install wpscan
else
    log "WPScan is already installed"
fi

# Install FFUF
log "Installing FFUF..."
if ! command -v ffuf >/dev/null 2>&1; then
    go install github.com/ffuf/ffuf/v2@latest
    mv $HOME/go/bin/ffuf /usr/local/bin/
else
    log "FFUF is already installed"
fi

# Install GAU
log "Installing GAU..."
if ! command -v gau >/dev/null 2>&1; then
    go install github.com/lc/gau/v2@latest
    mv $HOME/go/bin/gau /usr/local/bin/
else
    log "GAU is already installed"
fi

# Install waybackurls
log "Installing waybackurls..."
if ! command -v waybackurls >/dev/null 2>&1; then
    go install github.com/tomnomnom/waybackurls@latest
    mv $HOME/go/bin/waybackurls /usr/local/bin/
else
    log "waybackurls is already installed"
fi

# Install hakrawler
log "Installing hakrawler..."
if ! command -v hakrawler >/dev/null 2>&1; then
    go install github.com/hakluke/hakrawler@latest
    mv $HOME/go/bin/hakrawler /usr/local/bin/
else
    log "hakrawler is already installed"
fi

# Install Nuclei
log "Installing Nuclei..."
if ! command -v nuclei >/dev/null 2>&1; then
    go install github.com/projectdiscovery/nuclei/v3@latest
    mv $HOME/go/bin/nuclei /usr/local/bin/
    # Install Nuclei templates
    nuclei -update-templates
else
    log "Nuclei is already installed"
fi

# Install Subjack
log "Installing Subjack..."
if ! command -v subjack >/dev/null 2>&1; then
    go install github.com/haccer/subjack@latest
    mv $HOME/go/bin/subjack /usr/local/bin/
    # Download fingerprints file
    wget -O /usr/local/share/subjack_fingerprints.json https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json
else
    log "Subjack is already installed"
fi

# Verify installations
log "Verifying tool installations..."
for tool in nmap sslscan wpscan ffuf gau waybackurls hakrawler nuclei subjack; do
    if command -v "$tool" >/dev/null 2>&1; then
        log "$tool installed successfully"
    else
        warning_log "$tool installation failed"
    fi
done

log "Installation complete!"
log "Subjack fingerprints installed at: /usr/local/share/subjack_fingerprints.json"
log "Please ensure the wp-scan-script.sh has correct paths for SUBJACK_FINGERPRINTS:"
log "SUBJACK_FINGERPRINTS=\"/usr/local/share/subjack_fingerprints.json\""
