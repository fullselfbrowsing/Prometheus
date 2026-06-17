#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${SOURCE_ROOT}/build/fsb-baseline"
OUTPUT_DIR=""
APP_BUNDLE=""

usage() {
  cat <<'USAGE'
Usage: package-macos.sh [--build-dir DIR] [--app PATH] [--output-dir DIR]

Creates a macOS Prometheus release bundle with required legal/source
notices and a compressed tarball artifact.

Options:
  --build-dir DIR   Build directory. Defaults to build/fsb-baseline.
  --app PATH        Built prometheus.app bundle to package.
  --output-dir DIR  Output directory. Defaults to BUILD_DIR/release.
  --help            Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --build-dir)
      BUILD_DIR="${2:-}"
      shift 2
      ;;
    --app)
      APP_BUNDLE="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
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

if [ -z "$APP_BUNDLE" ]; then
  APP_BUNDLE="${BUILD_DIR}/bin/prometheus.app"
fi
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="${BUILD_DIR}/release"
fi

if [ ! -d "$APP_BUNDLE" ]; then
  printf 'App bundle not found: %s\n' "$APP_BUNDLE" >&2
  exit 1
fi

RELEASE_ROOT="${OUTPUT_DIR}/Prometheus-macos"
ARTIFACT="${OUTPUT_DIR}/Prometheus-macos.tar.gz"
LEGAL_DIR="${RELEASE_ROOT}/LEGAL"
PACKAGED_APP="${RELEASE_ROOT}/Prometheus.app"
FRAMEWORKS_DIR="${PACKAGED_APP}/Contents/Frameworks"
RESOURCES_DIR="${PACKAGED_APP}/Contents/Resources"

rm -rf "$RELEASE_ROOT" "$ARTIFACT"
mkdir -p "$LEGAL_DIR"

ditto "$APP_BUNDLE" "$PACKAGED_APP"
mkdir -p "$FRAMEWORKS_DIR" "$RESOURCES_DIR"

cp "${BUILD_DIR}/bin/libFalkonPrivate.dylib" "$FRAMEWORKS_DIR/"
if [ -d "${BUILD_DIR}/bin/plugins" ]; then
  ditto "${BUILD_DIR}/bin/plugins" "${RESOURCES_DIR}/plugins"
fi
if [ -d "${SOURCE_ROOT}/themes" ]; then
  ditto "${SOURCE_ROOT}/themes" "${RESOURCES_DIR}/themes"
fi

if command -v install_name_tool >/dev/null 2>&1; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "${PACKAGED_APP}/Contents/MacOS/prometheus" 2>/dev/null || true
fi

cp "${SOURCE_ROOT}/COPYING" "${LEGAL_DIR}/GPL-3.0-or-later.txt"
cp "${SOURCE_ROOT}/themes/mac/license.txt" "${LEGAL_DIR}/theme-mac-license.txt"
cp "${SOURCE_ROOT}/themes/chrome/license.txt" "${LEGAL_DIR}/theme-chrome-license.txt"
cp "${SOURCE_ROOT}/src/lib/data/html/copyright" "${LEGAL_DIR}/falkon-kde-qt-copyright.html"

cat >"${LEGAL_DIR}/SOURCE-AVAILABILITY.txt" <<EOF
Prometheus is derived from the local Falkon/QtWebEngine source tree and
contains GPLv3-or-later code. Redistribution of this artifact must provide
corresponding source code and preserve third-party notices.

Workspace source root used for this artifact:
${SOURCE_ROOT}
EOF

cat >"${RELEASE_ROOT}/README.txt" <<'EOF'
Prometheus
Powered by FSB

This macOS artifact is a local validation bundle. See LEGAL/ for inherited
GPL and third-party notices that must accompany redistribution.
EOF

(cd "$OUTPUT_DIR" && tar -czf "$ARTIFACT" Prometheus-macos)

printf 'Packaged Prometheus macOS artifact: %s\n' "$ARTIFACT"
