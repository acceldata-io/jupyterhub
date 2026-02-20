#!/usr/bin/env bash
# Install additional Jupyter kernels (Toree for Scala/SQL, etc.)
# This script expects to run after the virtual environment has been created
# and requirements have been installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/env"
JUPYTER="${ENV_DIR}/bin/jupyter"

SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

echo "============================================"
echo "Installing Additional Jupyter Kernels"
echo "============================================"

# --- Apache Toree: Scala kernel ---
echo ""
echo "Installing Toree Scala kernel..."
"${JUPYTER}" toree install \
  --sys-prefix \
  --interpreters=Scala \
  --spark_home="${SPARK_HOME}" \
  --spark_opts="--conf spark.sql.catalogImplementation=hive"

# --- Apache Toree: SQL kernel ---
echo ""
echo "Installing Toree SQL kernel..."
"${JUPYTER}" toree install \
  --sys-prefix \
  --interpreters=SQL \
  --spark_home="${SPARK_HOME}" \
  --spark_opts="--conf spark.sql.catalogImplementation=hive"

echo ""
echo "============================================"
echo "Additional kernels installation complete!"
echo "============================================"

echo ""
echo "Installed Jupyter kernels:"
"${JUPYTER}" kernelspec list
