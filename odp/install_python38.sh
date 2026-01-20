#!/usr/bin/env bash
# Install Python 3.8 on various Linux distributions
# Run this script as root
# Supported OS: RHEL 8+, Ubuntu 20.04/22.04
# This script is idempotent - safe to run multiple times
set -euo pipefail

# Version configuration
PYTHON_VERSION="3.8.12"
PYTHON_MAJOR_MINOR="3.8"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_VERSION_ID="${VERSION_ID:-}"
        OS_VERSION_MAJOR=$(echo "$OS_VERSION_ID" | cut -d. -f1)
    elif [ -f /etc/redhat-release ]; then
        OS_ID="rhel"
        OS_VERSION_ID=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
        OS_VERSION_MAJOR="$OS_VERSION_ID"
    else
        echo "ERROR: Unable to detect OS."
        exit 1
    fi
    
    echo "Detected OS: ${OS_ID} ${OS_VERSION_ID}"
}

# Check if Python 3.8 is already installed and working
check_python38() {
    if command -v python${PYTHON_MAJOR_MINOR} &>/dev/null; then
        INSTALLED_PY_VERSION=$(python${PYTHON_MAJOR_MINOR} --version 2>&1 | awk '{print $2}')
        echo "Found Python ${INSTALLED_PY_VERSION}"
        
        # Check if sqlite3 module works
        if python${PYTHON_MAJOR_MINOR} -c "import sqlite3; print(sqlite3.sqlite_version)" &>/dev/null; then
            echo "Python ${PYTHON_MAJOR_MINOR} already installed with working sqlite3 module."
            return 0
        else
            echo "Python exists but sqlite3 module is broken. Will reinstall."
            return 1
        fi
    fi
    return 1
}

# ============================================================
# RHEL 8+ Installation (via yum/dnf)
# ============================================================
install_python38_rhel8() {
    echo "Installing Python 3.8 on RHEL/CentOS 8+ (via package manager)..."
    
    # Install Python 3.8
    echo "Installing Python 3.8 via yum..."
    yum install -y python38 python38-devel python38-pip || dnf install -y python38 python38-devel python38-pip
    
    echo "Python 3.8 installation complete via package manager."
}

# ============================================================
# Ubuntu 20.04/22.04 Installation (via deadsnakes PPA)
# ============================================================
install_python38_ubuntu() {
    echo "Installing Python 3.8 on Ubuntu ${OS_VERSION_ID} (via deadsnakes PPA)..."
    
    # Update apt
    echo "Updating package lists..."
    apt update -y
    
    # Install software-properties-common for add-apt-repository
    apt install -y software-properties-common
    
    # Add deadsnakes PPA
    echo "Adding deadsnakes PPA..."
    add-apt-repository -y ppa:deadsnakes/ppa
    
    # Update after adding PPA
    apt update -y
    
    # Install Python 3.8 and related packages
    echo "Installing Python 3.8 and related packages..."
    apt install -y python3.8 python3.8-venv python3.8-dev
    
    # Install distutils (needed for pip)
    apt install -y python3.8-distutils || true
    
    # Ensure pip is available for Python 3.8
    if ! python3.8 -m pip --version &>/dev/null; then
        echo "Installing pip for Python 3.8..."
        # Use Python 3.8 specific get-pip.py (main get-pip.py requires Python 3.9+)
        curl -sS https://bootstrap.pypa.io/pip/3.8/get-pip.py | python3.8
    fi
    
    echo "Python 3.8 installation complete via deadsnakes PPA."
}

# ============================================================
# Main Installation Logic
# ============================================================

echo "============================================"
echo "Python ${PYTHON_VERSION} Installation Script"
echo "============================================"

detect_os

# Check if Python 3.8 is already properly installed
if check_python38; then
    echo "Python 3.8 is already installed and working. Skipping installation."
else
    # Install based on detected OS
    case "${OS_ID}" in
        rhel|rocky|almalinux|fedora)
            install_python38_rhel8
            ;;
        ubuntu)
            if [[ "${OS_VERSION_MAJOR}" =~ ^(20|22|24)$ ]]; then
                install_python38_ubuntu
            else
                echo "WARNING: Ubuntu ${OS_VERSION_ID} may not be fully supported."
                install_python38_ubuntu
            fi
            ;;
        debian)
            echo "Detected Debian - using Ubuntu installation method"
            install_python38_ubuntu
            ;;
        *)
            echo "ERROR: Unsupported OS: ${OS_ID}"
            echo "Supported: RHEL 8+, Rocky8+, Ubuntu 20/22"
            exit 1
            ;;
    esac
fi

# ============================================================
# Verification
# ============================================================
echo ""
echo "============================================"
echo "Installation Verification"
echo "============================================"

echo "Python version:"
python${PYTHON_MAJOR_MINOR} --version

echo "Python location:"
which python${PYTHON_MAJOR_MINOR}

echo "SQLite version (in Python):"
python${PYTHON_MAJOR_MINOR} -c "import sqlite3; print(sqlite3.sqlite_version)" || echo "WARNING: sqlite3 module not working"

# Verify venv works
echo "Checking venv module:"
python${PYTHON_MAJOR_MINOR} -m venv --help &>/dev/null && echo "venv module: OK" || echo "WARNING: venv module not working"

echo ""
echo "============================================"
echo "Python 3.8 Installation complete!"
echo "============================================"
