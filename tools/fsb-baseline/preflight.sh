#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATUS=0

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  STATUS=1
}

warn() {
  printf 'WARN %s\n' "$1" >&2
}

require_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    pass "${name}: $(command -v "$name")"
  else
    fail "${name}: missing from PATH"
  fi
}

check_cmake_package_hint() {
  local package="$1"
  local found
  found="$(find /opt/homebrew /usr/local "$HOME/Qt" -path "*/${package}Config.cmake" -o -path "*/${package}-config.cmake" 2>/dev/null | head -1 || true)"
  if [ -n "$found" ]; then
    pass "${package}: ${found}"
  else
    warn "${package}: CMake package metadata not found in common macOS prefixes"
  fi
}

printf 'Prometheus baseline preflight\n'
printf 'Source root: %s\n\n' "$SOURCE_ROOT"

if [ ! -f "${SOURCE_ROOT}/CMakeLists.txt" ]; then
  fail "CMakeLists.txt not found at source root"
fi

require_command cmake
require_command ninja
require_command git

check_cmake_package_hint Qt6
check_cmake_package_hint Qt6WebEngineCore
check_cmake_package_hint ECM
check_cmake_package_hint KF6Archive

printf '\nRecommended configure command after prerequisites are installed:\n'
printf '  cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo\n'

exit "$STATUS"
