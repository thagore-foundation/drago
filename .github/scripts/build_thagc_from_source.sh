#!/usr/bin/env bash
set -euo pipefail

THAGORE_REF="${1:-main}"
THAGORE_URL="https://github.com/thagore-foundation/thagore.git"
WORK_ROOT="${RUNNER_TEMP:-/tmp}"
SRC_DIR="${WORK_ROOT}/thagore-src"
BUILD_DIR="${SRC_DIR}/build-llvm21"

rm -rf "${SRC_DIR}"
git clone --depth 1 --branch "${THAGORE_REF}" "${THAGORE_URL}" "${SRC_DIR}"

cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" -G Ninja \
  -DLLVM_DIR=/usr/lib/llvm-21/lib/cmake/llvm

cmake --build "${BUILD_DIR}" -j"$(nproc)"

if [[ -z "${GITHUB_PATH:-}" ]]; then
  echo "GITHUB_PATH is required in GitHub Actions" >&2
  exit 1
fi

echo "${BUILD_DIR}/compiler" >> "${GITHUB_PATH}"
"${BUILD_DIR}/compiler/thagc" --version
