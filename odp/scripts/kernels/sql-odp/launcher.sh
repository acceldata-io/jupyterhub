#!/usr/bin/env bash
# SQL (JupySQL) kernel launcher
# Self-locating: finds venv root relative to this script's location

KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_ROOT="$(cd "${KERNEL_DIR}/../../../.." && pwd)"

export JUPYSQL_AUTOLOAD=1

exec "${VENV_ROOT}/bin/python3.11" -m ipykernel_launcher "$@"
