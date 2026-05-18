#!/usr/bin/env bash
# Common functions for kernel launchers

find_venv_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/pyvenv.cfg" ]] && { printf "%s" "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  echo "ERROR: could not find virtual environment root (pyvenv.cfg)" >&2
  return 1
}
