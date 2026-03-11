#!/usr/bin/env bash
set -euo pipefail

THAGC_TAG="${1:-v0.9.6}"
CHANNEL="${2:-indev}"
ARCH="${3:-}"
PREFIX="${HOME}/.thagore"
TMP_ARCHIVE="$(mktemp)"

cleanup() {
  rm -f "${TMP_ARCHIVE}"
}
trap cleanup EXIT

TARGET=""
case "$(uname -s)" in
  Linux)
    case "${ARCH}" in
      aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
      ""|x86_64|amd64) TARGET="x86_64-unknown-linux-gnu" ;;
      *) echo "unsupported Linux arch: ${ARCH}" >&2; exit 2 ;;
    esac
    ;;
  Darwin)
    case "${ARCH}" in
      aarch64|arm64|"") TARGET="aarch64-apple-darwin" ;;
      x86_64|amd64) TARGET="x86_64-apple-darwin" ;;
      *) echo "unsupported macOS arch: ${ARCH}" >&2; exit 2 ;;
    esac
    ;;
  *)
    echo "unsupported host OS" >&2
    exit 2
    ;;
esac

ASSET_URL="https://github.com/thagore-foundation/thagore/releases/download/${THAGC_TAG}/thagore-${THAGC_TAG#v}-${TARGET}.tar.gz"

echo "installing thagc ${THAGC_TAG} (${CHANNEL})"
rm -rf "${PREFIX}"
mkdir -p "${PREFIX}"
curl -fsSL "${ASSET_URL}" -o "${TMP_ARCHIVE}"
tar -xzf "${TMP_ARCHIVE}" -C "${PREFIX}" --strip-components=1

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${PREFIX}/bin" >>"${GITHUB_PATH}"
fi

"${PREFIX}/bin/thagc" --version
