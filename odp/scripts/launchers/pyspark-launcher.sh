#!/bin/bash
# PySpark kernel launcher
# Reads SPARK_HOME from environment (set by JupyterHub pre_spawn_hook)
# Self-locating: works in both LocalSpawner and YarnSpawner modes

set -e

if [ -z "$SPARK_HOME" ]; then
  echo "ERROR: SPARK_HOME is not set." >&2
  exit 1
fi

# Find the py4j zip for this Spark version
PY4J_ZIP=$(ls "$SPARK_HOME"/python/lib/py4j-*-src.zip 2>/dev/null | head -1)
if [ -z "$PY4J_ZIP" ]; then
  PY4J_ZIP="$SPARK_HOME/python/lib/py4j-src.zip"
fi

export PYTHONPATH="$SPARK_HOME/python:$PY4J_ZIP${PYTHONPATH:+:$PYTHONPATH}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"

# Self-locate: find Python relative to this script's location
# This script lives at <venv>/pyspark-launcher.sh, Python at <venv>/bin/python3.11
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${SCRIPT_DIR}/bin/python3.11"

exec "$PYTHON_BIN" -m ipykernel_launcher "$@"
