#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SMOKE_URL_1='data:text/html,<title>FSB%20Smoke%201</title><h1>FSB Smoke 1</h1>'
SMOKE_URL_2='data:text/html,<title>FSB%20Smoke%202</title><h1>FSB Smoke 2</h1>'
WAIT_SECONDS=8
BINARY=""

usage() {
  cat <<'USAGE'
Usage: smoke-browser.sh [--binary PATH] [--wait SECONDS]

Launches a built Prometheus browser binary, opens a first smoke URL,
attempts a second URL invocation, waits briefly, then terminates the
launched process.

Options:
  --binary PATH   Browser executable to launch.
  --wait SECONDS  Seconds to keep the browser alive before termination.
  --help          Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --binary)
      BINARY="${2:-}"
      shift 2
      ;;
    --wait)
      WAIT_SECONDS="${2:-}"
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
  for candidate in \
    "${SOURCE_ROOT}/build/fsb-baseline/bin/prometheus.app/Contents/MacOS/prometheus" \
    "${SOURCE_ROOT}/build/fsb-baseline/bin/prometheus" \
    "${SOURCE_ROOT}/build/fsb-baseline/bin/falkon" \
    "${SOURCE_ROOT}/build/fsb-baseline/src/main/falkon" \
    "${SOURCE_ROOT}/build/fsb-baseline/bin/Falkon.app/Contents/MacOS/Falkon"
  do
    if [ -x "$candidate" ]; then
      BINARY="$candidate"
      break
    fi
  done
fi

if [ -z "$BINARY" ] || [ ! -x "$BINARY" ]; then
  cat >&2 <<EOF
No executable browser binary found.

Run preflight and build first:
  ./tools/fsb-baseline/preflight.sh
  cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
  cmake --build build/fsb-baseline

Or pass an explicit binary:
  ./tools/fsb-baseline/smoke-browser.sh --binary /path/to/prometheus
EOF
  exit 1
fi

LOG_FILE="${TMPDIR:-/tmp}/fsb-browser-smoke.$$.log"
printf 'Launching: %s\n' "$BINARY"
printf 'Smoke log: %s\n' "$LOG_FILE"

PIDS=()

"$BINARY" "$SMOKE_URL_1" >"$LOG_FILE" 2>&1 &
PIDS+=("$!")

sleep 2
"$BINARY" "$SMOKE_URL_2" >>"$LOG_FILE" 2>&1 &
PIDS+=("$!")

sleep "$WAIT_SECONDS"

for pid in "${PIDS[@]}"; do
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
done

for pid in "${PIDS[@]}"; do
  wait "$pid" >/dev/null 2>&1 || true
done

printf 'Smoke launch completed. Review log: %s\n' "$LOG_FILE"
