#!/usr/bin/env bash
set -euo pipefail

THAGC_TAG="${1:-v0.9.6}"
CHANNEL="${2:-indev}"
ARCH="${3:-}"
SCRIPT_URL="https://github.com/thagore-foundation/thagore/releases/latest/download/thagup.sh"
PREFIX="${HOME}/.thagore"
TMP_SCRIPT="$(mktemp)"

cleanup() {
  rm -f "${TMP_SCRIPT}"
}
trap cleanup EXIT

echo "installing thagc ${THAGC_TAG} (${CHANNEL})"
curl -fsSL "${SCRIPT_URL}" -o "${TMP_SCRIPT}"
if [[ -n "${ARCH}" ]]; then
  bash "${TMP_SCRIPT}" --tag "${THAGC_TAG}" --channel "${CHANNEL}" --arch "${ARCH}" --prefix "${PREFIX}" --force
else
  bash "${TMP_SCRIPT}" --tag "${THAGC_TAG}" --channel "${CHANNEL}" --prefix "${PREFIX}" --force
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${PREFIX}/bin" >>"${GITHUB_PATH}"
fi

"${PREFIX}/bin/thagc" --version
