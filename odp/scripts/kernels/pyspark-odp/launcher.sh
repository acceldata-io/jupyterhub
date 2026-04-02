#!/usr/bin/env bash
# PySpark kernel launcher
# Self-locating: finds venv root by walking up to pyvenv.cfg

KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"

find_venv_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/pyvenv.cfg" ]] && { printf "%s" "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  echo "ERROR: could not find virtual environment root (pyvenv.cfg)" >&2
  return 1
}

VENV_ROOT="$(find_venv_root "$KERNEL_DIR")" || exit 1

if [[ ! -x "${VENV_ROOT}/bin/python3" ]]; then
  echo "ERROR: python3 not found in venv at ${VENV_ROOT}/bin/python3" >&2
  exit 1
fi

export SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

# Executor Python: system Python (available on all nodes)
export PYSPARK_PYTHON="/usr/bin/python3"

# Driver Python: venv Python (on JupyterHub node)
export PYSPARK_DRIVER_PYTHON="${VENV_ROOT}/bin/python3"

export PYTHONPATH="${SPARK_HOME}/python:${PYTHONPATH}"
export PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/bin:/bin:${PATH}"

exec "${VENV_ROOT}/bin/python3" -m ipykernel_launcher "$@"
