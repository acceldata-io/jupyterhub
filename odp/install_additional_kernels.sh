#!/usr/bin/env bash
# Install additional Jupyter kernels (Toree for Scala/SQL, PySpark, SparkR)
# This script expects to run after the virtual environment has been created
# and requirements have been installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/env"
JUPYTER="${ENV_DIR}/bin/jupyter"

SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"
KERNELS_SRC="${SCRIPT_DIR}/kernels"
KERNELS_DEST="${ENV_DIR}/share/jupyter/kernels"

VERSION_FILE="${SCRIPT_DIR}/VERSION"
if [ ! -f "${VERSION_FILE}" ]; then
    echo "ERROR: VERSION file not found at ${VERSION_FILE}"
    exit 1
fi
ODP_VERSION=$(cat "${VERSION_FILE}" | tr -d '[:space:]')

PY="${PY:-python3.11}"

# Where the venv will live after deployment
RUNTIME_PREFIX="/usr/odp/${ODP_VERSION}/jupyterhub"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Toree bakes the build-time venv path into its generated files.
# Rewrite only text files (.json, .sh) — never touch jars or binaries.
rewrite_toree_paths() {
    local kernel_dir="$1"
    echo "  Fixing paths in ${kernel_dir##*/}/  (${ENV_DIR} -> ${RUNTIME_PREFIX})"
    find "${kernel_dir}" -type f \( -name '*.json' -o -name '*.sh' \) \
        -exec sed -i "s|${ENV_DIR}|${RUNTIME_PREFIX}|g" {} +
}

# Copy a kernel template directory into the venv, replacing placeholders:
#   __ODP_VERSION__   ->  ODP version from VERSION file
#   __PY__            ->  python binary name (e.g. python3.11)
#   __RUNTIME_PREFIX__ -> deployment path (e.g. /usr/odp/3.3.6.3-SNAPSHOT/jupyterhub)
install_kernel_template() {
    local name="$1"
    local dest="${KERNELS_DEST}/${name}"
    mkdir -p "${dest}"
    for src_file in "${KERNELS_SRC}/${name}"/*; do
        local filename
        filename=$(basename "${src_file}")
        sed -e "s|__ODP_VERSION__|${ODP_VERSION}|g" \
            -e "s|__PY__|${PY}|g" \
            -e "s|__RUNTIME_PREFIX__|${RUNTIME_PREFIX}|g" \
            "${src_file}" > "${dest}/${filename}"
    done
    find "${dest}" -name '*.sh' -exec chmod +x {} +
}

echo "============================================"
echo "Installing Additional Jupyter Kernels"
echo "  ODP_VERSION    = ${ODP_VERSION}"
echo "  PY             = ${PY}"
echo "  RUNTIME_PREFIX = ${RUNTIME_PREFIX}"
echo "  SPARK_HOME     = ${SPARK_HOME}"
echo "============================================"

# --- Apache Toree: Scala kernel ---
echo ""
echo "Installing Toree Scala kernel..."
"${JUPYTER}" toree install \
  --sys-prefix \
  --interpreters=Scala \
  --spark_home="${SPARK_HOME}" \
  --spark_opts="--conf spark.sql.catalogImplementation=hive"
rewrite_toree_paths "${KERNELS_DEST}/apache_toree_scala"

# --- Apache Toree: SQL kernel ---
echo ""
echo "Installing Toree SQL kernel..."
"${JUPYTER}" toree install \
  --sys-prefix \
  --interpreters=SQL \
  --spark_home="${SPARK_HOME}" \
  --spark_opts="--conf spark.sql.catalogImplementation=hive"
rewrite_toree_paths "${KERNELS_DEST}/apache_toree_sql"

# --- PySpark kernel ---
echo ""
echo "Installing PySpark kernel..."
install_kernel_template "pyspark-odp"

# --- SparkR kernel ---
echo ""
echo "Installing SparkR kernel..."
install_kernel_template "sparkr-odp"

echo ""
echo "============================================"
echo "Additional kernels installation complete!"
echo "============================================"

echo ""
echo "Installed Jupyter kernels:"
"${JUPYTER}" kernelspec list
