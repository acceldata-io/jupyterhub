#!/usr/bin/env bash
# Build and install Apache Toree from the acceldata-io fork (ODP-6326 branch).
# This branch includes the display_data fix not present in upstream PyPI releases.
#
# Requires: git, java, sbt
#
# Usage: install_toree.sh <venv_dir>
#   venv_dir  Path to the Python virtual environment where Toree will be installed
set -euo pipefail

TOREE_REPO="https://github.com/acceldata-io/incubator-toree.git"
TOREE_BRANCH="ODP-6326"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${1:?Usage: install_toree.sh <venv_dir>}"
TOREE_BUILD_DIR="${SCRIPT_DIR}/_toree_build"

echo "============================================"
echo "Building Apache Toree from source (${TOREE_BRANCH})"
echo "============================================"

for cmd in git java sbt; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '${cmd}' is required to build Toree but was not found in PATH."
        exit 1
    fi
done

JAVA_VER=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+[^"]*).*/\1/')
case "${JAVA_VER}" in
    1.8*|1.8.*)
        echo "Java version OK: ${JAVA_VER}"
        ;;
    *)
        echo "ERROR: Toree requires Java 8 to compile (found: ${JAVA_VER})."
        echo "Set JAVA_HOME to a JDK 8 installation and ensure it is first in PATH."
        exit 1
        ;;
esac

rm -rf "${TOREE_BUILD_DIR}"
git clone --branch "${TOREE_BRANCH}" --depth 1 "${TOREE_REPO}" "${TOREE_BUILD_DIR}"

pushd "${TOREE_BUILD_DIR}" > /dev/null

echo "Running 'make build'..."
make build

echo "Running 'make dist'..."
make dist

echo "Installing Toree pip package into venv..."
"${VENV_DIR}/bin/python" -m pip install --no-cache-dir dist/toree-pip/toree-*.tar.gz

popd > /dev/null

rm -rf "${TOREE_BUILD_DIR}"

echo "============================================"
echo "Toree built and installed from source successfully."
echo "============================================"
