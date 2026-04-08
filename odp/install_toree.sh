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

# The upstream 'make dist' shells out to Docker for 'python setup.py sdist'.
# We replicate those steps locally using the venv's Python instead.
echo "Packaging Toree pip distribution (without Docker)..."
make dist/toree

BASE_VERSION=$(grep -oP '^BASE_VERSION\?=\K.*' Makefile)
COMMIT=$(git rev-parse --short=12 --verify HEAD)

mkdir -p dist/toree-pip
cp -r dist/toree dist/toree-pip/
cp dist/toree/LICENSE dist/toree-pip/LICENSE
cp dist/toree/NOTICE dist/toree-pip/NOTICE
cp dist/toree/DISCLAIMER dist/toree-pip/DISCLAIMER
cp dist/toree/VERSION dist/toree-pip/VERSION
cp dist/toree/RELEASE_NOTES.md dist/toree-pip/RELEASE_NOTES.md
cp -R dist/toree/licenses dist/toree-pip/licenses
cp -rf etc/pip_install/* dist/toree-pip/
printf "__version__ = '${BASE_VERSION}'\n" >> dist/toree-pip/toree/_version.py
printf "__commit__ = '${COMMIT}'\n" >> dist/toree-pip/toree/_version.py

pushd dist/toree-pip > /dev/null
"${VENV_DIR}/bin/python" setup.py sdist --dist-dir=.
popd > /dev/null

echo "Installing Toree pip package into venv..."
"${VENV_DIR}/bin/python" -m pip install --no-cache-dir dist/toree-pip/toree-*.tar.gz

popd > /dev/null

rm -rf "${TOREE_BUILD_DIR}"

echo "============================================"
echo "Toree built and installed from source successfully."
echo "============================================"
