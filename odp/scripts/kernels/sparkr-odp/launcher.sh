#!/usr/bin/env bash
# SparkR kernel launcher
# Self-locating: finds venv root relative to this script's location

KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_ROOT="$(cd "${KERNEL_DIR}/../../../.." && pwd)"

# SPARK_HOME is set by JupyterHub pre_spawn_hook, fall back to default
export SPARK_HOME="${SPARK_HOME:-/usr/odp/current/spark3-client}"

export R_LIBS_SITE="${SPARK_HOME}/R/lib${R_LIBS_SITE:+:$R_LIBS_SITE}"
export PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/bin:/bin:${PATH}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"

exec /usr/lib64/R/bin/R --slave -e "IRkernel::main()" --args "$@"
