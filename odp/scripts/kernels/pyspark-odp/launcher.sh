#!/usr/bin/env bash
# PySpark kernel launcher
# Self-locating: finds venv root by walking up to pyvenv.cfg

KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$(dirname "$0")/../_common.sh"

VENV_ROOT="$(find_venv_root "$KERNEL_DIR")" || exit 1

if [[ ! -x "${VENV_ROOT}/bin/python3" ]]; then
  echo "ERROR: python3 not found in venv at ${VENV_ROOT}/bin/python3" >&2
  exit 1
fi

export SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

if [[ ! -d "$SPARK_HOME" ]]; then
  echo "WARNING: SPARK_HOME directory not found at $SPARK_HOME" >&2
fi

# Executor Python: system Python (available on all nodes)
export PYSPARK_PYTHON="/usr/bin/python3"

# Driver Python: venv Python (on JupyterHub node)
export PYSPARK_DRIVER_PYTHON="${VENV_ROOT}/bin/python3"

export PYTHONPATH="${SPARK_HOME}/python:${PYTHONPATH}"
export PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/bin:/bin:${PATH}"

exec "${VENV_ROOT}/bin/python3" -m ipykernel_launcher "$@"
