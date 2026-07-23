#!/usr/bin/env bash
# Install Python 3.14 on various Linux distributions
# Run this script as root
# Supported OS: RHEL 8/9, Rocky 8/9, Ubuntu 20/22
# This script is idempotent - safe to run multiple times
set -euo pipefail

# Version configuration
PYTHON_VERSION="3.14"
PYTHON_MAJOR_MINOR="3.14"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_VERSION_ID="${VERSION_ID:-}"
        OS_VERSION_MAJOR=$(echo "$OS_VERSION_ID" | cut -d. -f1)
    else
        echo "ERROR: Unable to detect OS."
        exit 1
    fi
    
    echo "Detected OS: ${OS_ID} ${OS_VERSION_ID}"
}

# Check if Python 3.14 is already installed and working
check_python314() {
    if command -v python${PYTHON_MAJOR_MINOR} &>/dev/null; then
        INSTALLED_PY_VERSION=$(python${PYTHON_MAJOR_MINOR} --version 2>&1 | awk '{print $2}')
        echo "Found Python ${INSTALLED_PY_VERSION}"
        
        # Check if venv module works
        if python${PYTHON_MAJOR_MINOR} -m venv --help &>/dev/null; then
            echo "Python ${PYTHON_MAJOR_MINOR} already installed with working venv module."
            return 0
        else
            echo "Python exists but venv module is broken. Will reinstall."
            return 1
        fi
    fi
    return 1
}

build_python314_from_source(){
    echo "Downloading Python 3.14 source..."
    cd /usr/src
    wget https://www.python.org/ftp/python/3.14.0/Python-3.14.0.tgz
    tar xzf Python-3.14.0.tgz
    cd Python-3.14.0

    echo "Configuring and building..."
    ./configure --enable-optimizations
    make -j "$(nproc)"
    make altinstall

    if ! command -v python${PYTHON_MAJOR_MINOR} >/dev/null 2>&1; then
      echo "Adding /usr/local/bin to PATH..."
      echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile.d/python314.sh
      export PATH="/usr/local/bin:$PATH"
    fi

    echo "Python 3.14 installation complete via source build."
}

# ============================================================
# RHEL/Rocky 8/9 Installation
# RHEL/Rocky 8 does not support Python 3.14 by default -> build from source
# RHEL/Rocky 9 -> default package manager install
# ============================================================
install_python314_rhel() {
    echo "Installing Python 3.14 on ${OS_ID} ${OS_VERSION_ID}..."

    if [[ "${OS_VERSION_MAJOR}" == "8" ]]; then
        echo "${OS_ID} ${OS_VERSION_ID} does not support Python 3.14 by default. Building from source..."

        local DEP_LIST="gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make xz-devel sqlite-devel readline-devel tk-devel"

        echo "Installing build dependencies for Python 3.14..."
        yum groupinstall -y "Development Tools" || dnf groupinstall -y "Development Tools"
        yum install -y ${DEP_LIST} || dnf install -y ${DEP_LIST}

        build_python314_from_source
    else
        echo "Installing Python 3.14 via default package manager on ${OS_ID} ${OS_VERSION_ID}..."

        dnf install -y python3.14 python3.14-pip || yum install -y python3.14 python3.14-pip

        echo "Python 3.14 installation complete via package manager."
    fi
}

# ============================================================
# Ubuntu 20/22 Installation
# Ubuntu 20 does not support Python 3.14 by default -> build from source
# Ubuntu 22 -> default package manager install (deadsnakes PPA)
# ============================================================
install_python314_ubuntu() {
    echo "Installing Python 3.14 on Ubuntu ${OS_VERSION_ID}..."

    if [[ "${OS_VERSION_MAJOR}" == "20" ]]; then
        echo "Ubuntu ${OS_VERSION_ID} does not support Python 3.14 by default. Building from source..."

        echo "Updating package lists..."
        apt update -y

        local DEP_LIST="build-essential gcc wget make libssl-dev zlib1g-dev libbz2-dev libffi-dev libsqlite3-dev libreadline-dev libncursesw5-dev xz-utils tk-dev"

        echo "Installing build dependencies for Python 3.14..."
        apt install -y ${DEP_LIST}

        build_python314_from_source
    else
        echo "Installing Python 3.14 via default package manager on Ubuntu ${OS_VERSION_ID}..."

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

        # Install Python 3.14 and related packages
        echo "Installing Python 3.14 and related packages..."
        apt install -y python3.14 python3.14-venv python3.14-dev

        # Install distutils (needed for pip)
        apt install -y python3.14-distutils || true

        # Ensure pip is available for Python 3.14
        if ! python3.14 -m pip --version &>/dev/null; then
            echo "Installing pip for Python 3.14..."
            curl -sS https://bootstrap.pypa.io/get-pip.py | python3.14
        fi

        echo "Python 3.14 installation complete via deadsnakes PPA."
    fi
}

# ============================================================
# Main Installation Logic
# ============================================================

echo "============================================"
echo "Python ${PYTHON_VERSION} Installation Script"
echo "============================================"

detect_os

# Check if Python 3.14 is already properly installed
if check_python314; then
    echo "Python 3.14 is already installed and working. Skipping installation."
else
    # Install based on detected OS
    case "${OS_ID}" in
        rhel|rocky)
            if [[ "${OS_VERSION_MAJOR}" =~ ^(8|9)$ ]]; then
                install_python314_rhel
            else
                echo "ERROR: ${OS_ID} ${OS_VERSION_ID} is not supported."
                exit 1
            fi
            ;;
        ubuntu)
            if [[ "${OS_VERSION_MAJOR}" =~ ^(20|22)$ ]]; then
                install_python314_ubuntu
            else
                echo "ERROR: Ubuntu ${OS_VERSION_ID} is not supported."
                exit 1
            fi
            ;;
        *)
            echo "ERROR: Unsupported OS: ${OS_ID}"
            echo "Supported: RHEL 8/9, Rocky 8/9, Ubuntu 20/22"
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

# Verify venv works
echo "Checking venv module:"
python${PYTHON_MAJOR_MINOR} -m venv --help &>/dev/null && echo "venv module: OK" || echo "WARNING: venv module not working"

echo ""
echo "============================================"
echo "Python 3.14 Installation complete!"
echo "============================================"
