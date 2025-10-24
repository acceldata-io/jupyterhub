#!/usr/bin/env bash
set -euo pipefail

PY=python3.8

echo "Creating virtual environment..."
$PY -m venv env

echo "Installing requirements..."
env/bin/python -m pip install --upgrade pip
env/bin/python -m pip install --no-cache-dir -r requirements.txt

echo "Detecting site-packages path..."
site_packages=$(env/bin/python -c "import site; print(site.getsitepackages()[0])")

# Copy custom files from scripts/site-packages to the virtual environment
echo "Copying custom files to site-packages..."
cp scripts/site-packages/yarnspawner/jupyter_labhub.py "${site_packages}/yarnspawner/jupyter_labhub.py"
cp scripts/site-packages/hdfscm/checkpoints.py "${site_packages}/hdfscm/checkpoints.py"
cp scripts/site-packages/hdfscm/hdfsmanager.py "${site_packages}/hdfscm/hdfsmanager.py"
cp scripts/site-packages/hdfscm/utils.py "${site_packages}/hdfscm/utils.py"

# Pack the environment
echo "Packing environment..."
# venv-pack must run from within the activated environment
source env/bin/activate
venv-pack -o jupyter-environment.tar.gz
deactivate

echo "Successfully created jupyter-environment.tar.gz"
