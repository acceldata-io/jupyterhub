#!/usr/bin/env bash
# Install prerequisites for JupyterHub environment
# Run this script as root
set -euo pipefail

echo "============================================"
echo "Installing Prerequisites"
echo "============================================"

echo "Installing libcurl-devel..."
sudo yum install -y libcurl-devel

echo "Installing build tools..."
sudo yum install -y gcc gcc-c++ make automake autoconf libtool kernel-devel patch

echo "============================================"
echo "Prerequisites installation complete!"
echo "============================================"
