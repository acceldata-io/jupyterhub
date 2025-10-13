python3_version="3.8"

python${python3_version} -m venv env
source env/bin/activate
pip${python3_version} install --no-cache-dir -r requirements.txt

# Copy custom files from scripts/site-packages to the virtual environment
cp scripts/site-packages/yarnspawner/jupyter_labhub.py env/lib/python${python3_version}/site-packages/yarnspawner/jupyter_labhub.py
cp scripts/site-packages/hdfscm/checkpoints.py env/lib/python${python3_version}/site-packages/hdfscm/checkpoints.py
cp scripts/site-packages/hdfscm/hdfsmanager.py env/lib/python${python3_version}/site-packages/hdfscm/hdfsmanager.py
cp scripts/site-packages/hdfscm/utils.py env/lib/python${python3_version}/site-packages/hdfscm/utils.py

venv-pack -o jupyter-environment.tar.gz

