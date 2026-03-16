#!/usr/bin/env bash
KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_ROOT="$(cd "${KERNEL_DIR}/../../../.." && pwd)"

export SPARK_HOME="/usr/odp/__ODP_VERSION__/spark3"
export PYSPARK_PYTHON="/usr/bin/__PY__"
export PYSPARK_DRIVER_PYTHON="${VENV_ROOT}/bin/__PY__"
export PYTHONPATH="/usr/odp/__ODP_VERSION__/spark3/python"
export PATH="/usr/odp/__ODP_VERSION__/spark3/bin:/usr/odp/__ODP_VERSION__/spark3/sbin:/usr/bin:/bin:${PATH}"

exec "${VENV_ROOT}/bin/__PY__" -m ipykernel_launcher "$@"
