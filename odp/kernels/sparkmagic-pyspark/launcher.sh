#!/usr/bin/env bash
KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_ROOT="$(cd "${KERNEL_DIR}/../../../.." && pwd)"

export SPARKMAGIC_CONF_DIR="${VENV_ROOT}/conf/sparkmagic"

exec "${VENV_ROOT}/bin/__PY__" -m sparkmagic.kernels.pysparkkernel.pysparkkernel "$@"
