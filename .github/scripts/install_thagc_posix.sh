#!/usr/bin/env bash
set -euo pipefail

THAGC_TAG="${1:-v1.0.0}"
CHANNEL="${2:-stable}"
SCRIPT_URL="https://raw.githubusercontent.com/thagore-foundation/thagore/main/tooling/release/thagup.sh"
TMP_SCRIPT="$(mktemp)"

cleanup() {
  rm -f "${TMP_SCRIPT}"
}
trap cleanup EXIT

echo "installing thagc ${THAGC_TAG} (${CHANNEL})"
curl -fsSL "${SCRIPT_URL}" -o "${TMP_SCRIPT}"
bash "${TMP_SCRIPT}" --tag "${THAGC_TAG}" --channel "${CHANNEL}" --force

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${HOME}/.thagore/bin" >>"${GITHUB_PATH}"
fi

"${HOME}/.thagore/bin/thagc" --version
