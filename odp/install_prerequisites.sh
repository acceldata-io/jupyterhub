#!/usr/bin/env bash
# Install prerequisites for JupyterHub environment
# Run this script as root
# Supported OS: RHEL 8+, Rocky 8+, Ubuntu 20.04/22.04
set -euo pipefail

echo "============================================"
echo "Installing Prerequisites"
echo "============================================"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
else
    echo "ERROR: Unable to detect OS."
    exit 1
fi

case "${OS_ID}" in
    rhel|rocky|almalinux|centos|fedora)
        echo "Detected ${OS_ID} - using yum/dnf..."
        
        echo "Installing libcurl-devel..."
        sudo yum install -y libcurl-devel

        echo "Installing build tools..."
        sudo yum install -y gcc gcc-c++ make automake autoconf libtool kernel-devel patch
        ;;
    ubuntu|debian)
        echo "Detected ${OS_ID} - using apt..."
        
        echo "Updating package lists..."
        sudo apt update -y

        echo "Installing libcurl-dev..."
        sudo apt install -y libcurl4-openssl-dev

        echo "Installing build tools..."
        sudo apt install -y build-essential make automake autoconf libtool patch
        ;;
    *)
        echo "WARNING: Unknown OS '${OS_ID}' - skipping prerequisites installation."
        echo "You may need to manually install: libcurl-dev, gcc, make, automake, autoconf, libtool, patch"
        ;;
esac

echo "============================================"
echo "Prerequisites installation complete!"
echo "============================================"
