#!/usr/bin/env bash
# Install the JupyterHub build interpreter.
# Run this script as root.
# Supported OS: RHEL/Rocky/Alma/CentOS/Oracle 8/9/10, Ubuntu 20/22.
# EL8/EL9 use Python 3.11. EL10 uses Python 3.12 (no python3.11 package).
# PYTHON_VER from the caller (python3.11 / python3.12) wins when set.
# This script is idempotent - safe to run multiple times.
set -euo pipefail

# Filled in after the OS is known.
PYTHON_VERSION=""
PYTHON_MAJOR_MINOR=""

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

# Check if the selected interpreter is already installed and working.
# On EL10 this must be python3.12. A preinstalled /usr/local/bin/python3.11
# is not a substitute: the venv would keep that path and fail on the target.
check_python() {
    if command -v "python${PYTHON_MAJOR_MINOR}" &>/dev/null; then
        INSTALLED_PY_VERSION=$(python${PYTHON_MAJOR_MINOR} --version 2>&1 | awk '{print $2}')
        echo "Found Python ${INSTALLED_PY_VERSION}"

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

select_python_version() {
    if [ -n "${PYTHON_VER:-}" ]; then
        PYTHON_MAJOR_MINOR="${PYTHON_VER#python}"
    elif [[ "${OS_ID}" =~ ^(rhel|rocky|centos|almalinux|ol|oraclelinux)$ ]] && [ "${OS_VERSION_MAJOR}" = "10" ]; then
        echo "RHEL ${OS_VERSION_MAJOR} ships Python 3.12 only."
        PYTHON_MAJOR_MINOR="3.12"
    else
        PYTHON_MAJOR_MINOR="3.11"
    fi
    PYTHON_VERSION="${PYTHON_MAJOR_MINOR}"
    echo "Selected Python: ${PYTHON_MAJOR_MINOR}"
}

# ============================================================
# RHEL/Rocky 8/9 Installation (via yum/dnf)
# ============================================================
install_python_rhel() {
    echo "Installing Python ${PYTHON_MAJOR_MINOR} on ${OS_ID} ${OS_VERSION_ID} (via package manager)..."

    if [ "${PYTHON_MAJOR_MINOR}" = "3.12" ]; then
        # EL10 dropped versioned AppStream packages. The python3 RPM is 3.12
        # and provides the python3.12 name and /usr/bin/python3.12.
        yum install -y python3 python3-devel python3-pip || dnf install -y python3 python3-devel python3-pip
    else
        yum install -y python3.11 python3.11-devel python3.11-pip || dnf install -y python3.11 python3.11-devel python3.11-pip
    fi

    echo "Python ${PYTHON_MAJOR_MINOR} installation complete via package manager."
}

# ============================================================
# Ubuntu 20/22 Installation (via deadsnakes PPA)
# ============================================================
install_python311_ubuntu() {
    echo "Installing Python 3.11 on Ubuntu ${OS_VERSION_ID} (via deadsnakes PPA)..."
    
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
    
    # Install Python 3.11 and related packages
    echo "Installing Python 3.11 and related packages..."
    apt install -y python3.11 python3.11-venv python3.11-dev
    
    # Install distutils (needed for pip)
    apt install -y python3.11-distutils || true
    
    # Ensure pip is available for Python 3.11
    if ! python3.11 -m pip --version &>/dev/null; then
        echo "Installing pip for Python 3.11..."
        curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
    fi
    
    echo "Python 3.11 installation complete via deadsnakes PPA."
}

# ============================================================
# Main Installation Logic
# ============================================================

echo "============================================"
echo "Python interpreter installation"
echo "============================================"

detect_os
select_python_version

if check_python; then
    echo "Python ${PYTHON_MAJOR_MINOR} is already installed and working. Skipping installation."
else
    case "${OS_ID}" in
        rhel|rocky|centos|almalinux|ol|oraclelinux)
            if [[ "${OS_VERSION_MAJOR}" =~ ^(8|9|10)$ ]]; then
                install_python_rhel
            else
                echo "ERROR: ${OS_ID} ${OS_VERSION_ID} is not supported."
                exit 1
            fi
            ;;
        ubuntu)
            if [[ "${OS_VERSION_MAJOR}" =~ ^(20|22)$ ]]; then
                if [ "${PYTHON_MAJOR_MINOR}" != "3.11" ]; then
                    echo "ERROR: Ubuntu prereqs install only Python 3.11 automatically."
                    exit 1
                fi
                install_python311_ubuntu
            else
                echo "ERROR: Ubuntu ${OS_VERSION_ID} is not supported."
                exit 1
            fi
            ;;
        *)
            echo "ERROR: Unsupported OS: ${OS_ID}"
            echo "Supported: RHEL/Rocky 8/9/10, Ubuntu 20/22"
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
echo "Python ${PYTHON_MAJOR_MINOR} installation complete!"
echo "============================================"
