#!/bin/bash
# SparkR kernel launcher
# Reads SPARK_HOME from environment (set by JupyterHub pre_spawn_hook)
# Works in both LocalSpawner and YarnSpawner modes

set -e

if [ -z "$SPARK_HOME" ]; then
  echo "ERROR: SPARK_HOME is not set." >&2
  exit 1
fi

export R_LIBS_SITE="$SPARK_HOME/R/lib${R_LIBS_SITE:+:$R_LIBS_SITE}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"

# R binary - must be installed on the system (not bundled in venv)
R_BIN="${R_BIN:-/usr/lib64/R/bin/R}"

exec "$R_BIN" --slave -e "IRkernel::main()" --args "$@"
