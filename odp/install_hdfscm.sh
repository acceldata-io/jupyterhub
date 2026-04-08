#!/usr/bin/env bash
# Install hdfscm from the acceldata-io fork (ODP-6326 branch).
#
# Usage: install_hdfscm.sh <venv_dir>
#   venv_dir  Path to the Python virtual environment where hdfscm will be installed
set -euo pipefail

HDFSCM_REPO="https://github.com/acceldata-io/hdfscm.git"
HDFSCM_BRANCH="ODP-6326"

VENV_DIR="${1:?Usage: install_hdfscm.sh <venv_dir>}"

echo "============================================"
echo "Installing hdfscm from source (${HDFSCM_BRANCH})"
echo "============================================"

"${VENV_DIR}/bin/python" -m pip install --no-cache-dir \
    "git+${HDFSCM_REPO}@${HDFSCM_BRANCH}"

echo "============================================"
echo "hdfscm installed from source successfully."
echo "============================================"
