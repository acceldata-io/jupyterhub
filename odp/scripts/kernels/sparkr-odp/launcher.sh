#!/usr/bin/env bash
# SparkR kernel launcher
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

# SPARK_HOME is set by JupyterHub pre_spawn_hook, fall back to default
export SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

export R_LIBS_SITE="${SPARK_HOME}/R/lib${R_LIBS_SITE:+:$R_LIBS_SITE}"
export PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/bin:/bin:${PATH}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"

R_BIN="${R_BIN:-/usr/lib64/R/bin/R}"

if [[ ! -x "$R_BIN" ]]; then
  echo "ERROR: R binary not found at $R_BIN" >&2
  exit 1
fi

exec "$R_BIN" --slave -e "IRkernel::main()" --args "$@"
