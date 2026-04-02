#!/usr/bin/env bash
# SQL (JupySQL) kernel launcher
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

export JUPYSQL_AUTOLOAD=1

exec "${VENV_ROOT}/bin/python3" -m ipykernel_launcher "$@"
