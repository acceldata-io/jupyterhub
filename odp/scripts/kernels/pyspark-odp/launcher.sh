#!/usr/bin/env bash
KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_ROOT="$(cd "${KERNEL_DIR}/../../../.." && pwd)"

export SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

# Executor Python: system Python (available on all nodes)
export PYSPARK_PYTHON="/usr/bin/python3"

# Driver Python: venv Python (on JupyterHub node)
export PYSPARK_DRIVER_PYTHON="${VENV_ROOT}/bin/python3.11"

export PYTHONPATH="${SPARK_HOME}/python:${PYTHONPATH}"
export PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/bin:/bin:${PATH}"

exec "${VENV_ROOT}/bin/python3.11" -m ipykernel_launcher "$@"
