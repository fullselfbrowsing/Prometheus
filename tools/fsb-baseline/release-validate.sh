#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${SOURCE_ROOT}/build/fsb-baseline"
BINARY=""

usage() {
  cat <<'USAGE'
Usage: release-validate.sh [--build-dir DIR] [--binary PATH]

Runs release validation for Prometheus: syntax checks, build, browser smoke,
native agent/runtime/supervision smoke, MCP bridge smoke, packaging, and legal
bundle checks.

Options:
  --build-dir DIR  Build directory. Defaults to build/fsb-baseline.
  --binary PATH    Browser executable to smoke test.
  --help           Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --build-dir)
      BUILD_DIR="${2:-}"
      shift 2
      ;;
    --binary)
      BINARY="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$BINARY" ]; then
  BINARY="${BUILD_DIR}/bin/prometheus.app/Contents/MacOS/prometheus"
fi

node --check "${SOURCE_ROOT}/tools/prometheus-mcp/server.mjs"
node --check "${SOURCE_ROOT}/tools/prometheus-mcp/smoke.mjs"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-agent-control.sh"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-compact-tabs.sh"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-mcp-bridge.sh"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/smoke-browser.sh"
bash -n "${SOURCE_ROOT}/tools/fsb-baseline/package-macos.sh"

cmake --build "$BUILD_DIR"

"${SOURCE_ROOT}/tools/fsb-baseline/smoke-agent-control.sh" --binary "$BINARY" --port 17885
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-mcp-bridge.sh" --binary "$BINARY" --port 17886
if [ -x "$BINARY" ]; then
  "${SOURCE_ROOT}/tools/fsb-baseline/smoke-compact-tabs.sh" --binary "$BINARY" --port 17887
else
  printf 'Skipping compact tab smoke; binary is unavailable at %s\n' "$BINARY" >&2
fi
"${SOURCE_ROOT}/tools/fsb-baseline/smoke-browser.sh" --binary "$BINARY" --wait 1

"${SOURCE_ROOT}/tools/fsb-baseline/package-macos.sh" --build-dir "$BUILD_DIR"

ARTIFACT="${BUILD_DIR}/release/Prometheus-macos.tar.gz"
LEGAL_DIR="${BUILD_DIR}/release/Prometheus-macos/LEGAL"
PACKAGED_BINARY="${BUILD_DIR}/release/Prometheus-macos/Prometheus.app/Contents/MacOS/prometheus"
test -s "$ARTIFACT"
test -s "${LEGAL_DIR}/GPL-3.0-or-later.txt"
test -s "${LEGAL_DIR}/SOURCE-AVAILABILITY.txt"
test -s "${LEGAL_DIR}/falkon-kde-qt-copyright.html"
test -s "${BUILD_DIR}/release/Prometheus-macos/Prometheus.app/Contents/Frameworks/libFalkonPrivate.dylib"
test -d "${BUILD_DIR}/release/Prometheus-macos/Prometheus.app/Contents/Resources/plugins"
test -d "${BUILD_DIR}/release/Prometheus-macos/Prometheus.app/Contents/Resources/themes"

"${SOURCE_ROOT}/tools/fsb-baseline/smoke-browser.sh" --binary "$PACKAGED_BINARY" --wait 1

printf 'Release validation completed. Artifact: %s\n' "$ARTIFACT"
