#!/usr/bin/env bash
set -euo pipefail

# Check if running on unsupported OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_MAJOR="${VERSION_ID%%.*}"
    
    if [ "$ID" = "centos" ] && [ "$OS_MAJOR" = "7" ]; then
        echo "JupyterHub with Python 3.8 on CentOS 7 is not supported."
        exit 1
    fi
    # RHEL 9, Rocky 9 don't have Python 3.8 packages
    if [[ "$ID" =~ ^(rhel|rocky)$ ]] && [ "$OS_MAJOR" = "9" ]; then
        echo "JupyterHub with Python 3.8 on ${ID} ${VERSION_ID} is not supported (Python 3.8 not available)."
        exit 1
    fi
fi

# Get script directory for resolving relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install prerequisites
bash "${SCRIPT_DIR}/install_prerequisites.sh"

# Install Python 3.8 if not available
bash "${SCRIPT_DIR}/install_python38.sh"

PY=python3.8

echo "Creating virtual environment..."
$PY -m venv "${SCRIPT_DIR}/env"

echo "Installing requirements..."
"${SCRIPT_DIR}/env/bin/python" -m pip install --upgrade pip
"${SCRIPT_DIR}/env/bin/python" -m pip install --no-cache-dir -r "${SCRIPT_DIR}/requirements.txt"

echo "Detecting site-packages path..."
site_packages=$("${SCRIPT_DIR}/env/bin/python" -c "import site; print(site.getsitepackages()[0])")

# Copy custom files from scripts/site-packages to the virtual environment
echo "Copying custom files to site-packages..."
cp "${SCRIPT_DIR}/scripts/site-packages/yarnspawner/jupyter_labhub.py" "${site_packages}/yarnspawner/jupyter_labhub.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/checkpoints.py" "${site_packages}/hdfscm/checkpoints.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/hdfsmanager.py" "${site_packages}/hdfscm/hdfsmanager.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/utils.py" "${site_packages}/hdfscm/utils.py"

# Pack the environment
echo "Packing environment..."
# venv-pack must run from within the activated environment
source "${SCRIPT_DIR}/env/bin/activate"
venv-pack -o "${SCRIPT_DIR}/jupyter-environment.tar.gz"
deactivate

echo "Successfully created ${SCRIPT_DIR}/jupyter-environment.tar.gz"
