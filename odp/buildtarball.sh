#!/usr/bin/env bash
set -euo pipefail

# Get script directory for resolving relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# VERSION CONFIGURATION
# =============================================================================
# NOTE: JUPYTERHUB_VERSION is used only for tarball naming convention.
# The actual JupyterHub package version is controlled by requirements.txt.
JUPYTERHUB_VERSION="5.2.1"

# Read ODP version from VERSION file
VERSION_FILE="${SCRIPT_DIR}/VERSION"
if [ ! -f "${VERSION_FILE}" ]; then
    echo "ERROR: VERSION file not found at ${VERSION_FILE}"
    exit 1
fi
ODP_VERSION=$(cat "${VERSION_FILE}" | tr -d '[:space:]')

if [ -z "${ODP_VERSION}" ]; then
    echo "ERROR: VERSION file is empty"
    exit 1
fi

# Combined version: upstream.odp (e.g., 5.2.1.3.2.3.5-3)
COMBINED_VERSION="${JUPYTERHUB_VERSION}.${ODP_VERSION}"

# Transform for tarball naming: dots and hyphens to underscores
COMBINED_VERSION_UNDERSCORE="${COMBINED_VERSION//./_}"
COMBINED_VERSION_UNDERSCORE="${COMBINED_VERSION_UNDERSCORE//-/_}"

TARBALL_NAME="jupyterhub_environment_${COMBINED_VERSION_UNDERSCORE}.tar.gz"

echo "Building JupyterHub environment tarball"
echo "  JupyterHub Version: ${JUPYTERHUB_VERSION}"
echo "  ODP Version: ${ODP_VERSION}"
echo "  Combined Version: ${COMBINED_VERSION}"
echo "  Tarball Name: ${TARBALL_NAME}"
echo ""

# =============================================================================
# BUILD PROCESS
# =============================================================================

# Check if running on unsupported OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_MAJOR="${VERSION_ID%%.*}"
    
    if [ "$ID" = "centos" ] && [ "$OS_MAJOR" = "7" ]; then
        echo "JupyterHub with Python 3.11 on CentOS 7 is not supported."
        exit 1
    fi
fi

# Install prerequisites
bash "${SCRIPT_DIR}/install_prerequisites.sh"

# Install Python 3.11 if not available
bash "${SCRIPT_DIR}/install_python311.sh"

PY=python3.11

echo "Creating virtual environment..."
$PY -m venv "${SCRIPT_DIR}/env"

echo "Installing requirements..."
"${SCRIPT_DIR}/env/bin/python" -m pip install --upgrade pip
"${SCRIPT_DIR}/env/bin/python" -m pip install --no-cache-dir -r "${SCRIPT_DIR}/requirements.txt"

echo "Installing PyTorch (CPU-only)..."
"${SCRIPT_DIR}/env/bin/python" -m pip install --no-cache-dir \
    torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 \
    --index-url https://download.pytorch.org/whl/cpu

echo "Detecting site-packages path..."
site_packages=$("${SCRIPT_DIR}/env/bin/python" -c "import site; print(site.getsitepackages()[0])")

# Copy custom files from scripts/site-packages to the virtual environment
echo "Copying custom files to site-packages..."
cp "${SCRIPT_DIR}/scripts/site-packages/yarnspawner/jupyter_labhub.py" "${site_packages}/yarnspawner/jupyter_labhub.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/checkpoints.py" "${site_packages}/hdfscm/checkpoints.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/hdfsmanager.py" "${site_packages}/hdfscm/hdfsmanager.py"
cp "${SCRIPT_DIR}/scripts/site-packages/hdfscm/utils.py" "${site_packages}/hdfscm/utils.py"

# Install Streamlit launcher (jupyter-server-proxy entry point for JupyterLab)
echo "Installing Streamlit launcher package..."
mkdir -p "${site_packages}/streamlit_launcher"
cp "${SCRIPT_DIR}/scripts/site-packages/streamlit_launcher/__init__.py" "${site_packages}/streamlit_launcher/__init__.py"
cp "${SCRIPT_DIR}/scripts/site-packages/streamlit_launcher/icon.svg" "${site_packages}/streamlit_launcher/icon.svg"
"${SCRIPT_DIR}/env/bin/python" -m pip install --no-cache-dir --no-deps \
    "${SCRIPT_DIR}/scripts/site-packages/streamlit_launcher/"

# =============================================================================
# MULTI-SPARK KERNEL LAUNCHERS AND KERNEL SPECS
# =============================================================================
# Kernel specs use {resource_dir} placeholder which Jupyter resolves at runtime.
# This makes kernels portable across LocalSpawner and YarnSpawner modes.

echo "Installing multi-Spark launcher scripts..."
cp "${SCRIPT_DIR}/scripts/launchers/pyspark-launcher.sh" "${SCRIPT_DIR}/env/pyspark-launcher.sh"
cp "${SCRIPT_DIR}/scripts/launchers/sparkr-launcher.sh" "${SCRIPT_DIR}/env/sparkr-launcher.sh"
chmod +x "${SCRIPT_DIR}/env/pyspark-launcher.sh" "${SCRIPT_DIR}/env/sparkr-launcher.sh"

KERNEL_DIR="${SCRIPT_DIR}/env/share/jupyter/kernels"
mkdir -p "${KERNEL_DIR}"

# Install Apache Toree (provides the bin/run.sh launcher)
echo "Installing Apache Toree..."
"${SCRIPT_DIR}/env/bin/python" -m pip install --no-cache-dir toree

# Install Toree to get the bin/run.sh scripts, then replace kernel.json with our versions
echo "Installing Toree kernel launchers..."
"${SCRIPT_DIR}/env/bin/jupyter" toree install \
    --sys-prefix \
    --interpreters=Scala,SQL \
    --spark_home=/usr/odp/current/spark3-client \
    --spark_opts="--conf spark.sql.catalogImplementation=hive"

# Copy all kernel specs (uses {resource_dir} for portable paths)
echo "Installing kernel specifications..."
for kernel in pyspark-odp sparkr-odp sql-odp apache_toree_scala apache_toree_sql; do
    mkdir -p "${KERNEL_DIR}/${kernel}"
    cp "${SCRIPT_DIR}/scripts/kernels/${kernel}/kernel.json" "${KERNEL_DIR}/${kernel}/kernel.json"
    echo "  Installed kernel: ${kernel}"
done

# Verify no SPARK_HOME in kernel specs
echo "Verifying kernel specs have no hardcoded SPARK_HOME..."
SPARK_HOME_MATCHES=$(grep -r "SPARK_HOME" "${KERNEL_DIR}"/*/kernel.json 2>/dev/null || true)
if [ -n "$SPARK_HOME_MATCHES" ]; then
    echo "WARNING: Found SPARK_HOME in kernel specs (this may cause issues):"
    echo "$SPARK_HOME_MATCHES"
else
    echo "  Verified: No SPARK_HOME found in kernel specs"
fi

# List installed kernels
echo ""
echo "Installed kernel specs:"
"${SCRIPT_DIR}/env/bin/jupyter" kernelspec list

# =============================================================================
# BUILD_INFO MANIFEST
# =============================================================================
echo ""
echo "Generating BUILD_INFO manifest..."

# Detect build OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    BUILD_OS="${ID}-${VERSION_ID}"
else
    BUILD_OS="unknown"
fi

# Get Python version
PYTHON_VERSION=$("${SCRIPT_DIR}/env/bin/python" --version 2>&1 | awk '{print $2}')

# Create BUILD_INFO inside the venv (will be included in tarball)
BUILD_INFO_FILE="${SCRIPT_DIR}/env/BUILD_INFO"
cat > "${BUILD_INFO_FILE}" <<EOF
JUPYTERHUB_VERSION=${JUPYTERHUB_VERSION}
ODP_VERSION=${ODP_VERSION}
ODP_JUPYTERHUB_VERSION=${COMBINED_VERSION}
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_OS=${BUILD_OS}
PYTHON_VERSION=${PYTHON_VERSION}
EOF

echo "BUILD_INFO contents:"
cat "${BUILD_INFO_FILE}"
echo ""

# =============================================================================
# PACK TARBALL
# =============================================================================
echo "Packing environment..."
# venv-pack must run from within the activated environment
source "${SCRIPT_DIR}/env/bin/activate"
venv-pack -o "${SCRIPT_DIR}/${TARBALL_NAME}"
deactivate

echo ""
echo "=========================================="
echo "Successfully created ${SCRIPT_DIR}/${TARBALL_NAME}"
echo "=========================================="
