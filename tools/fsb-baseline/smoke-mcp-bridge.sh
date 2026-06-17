#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BINARY=""
PORT="${PROMETHEUS_AGENT_PORT:-17882}"
PROFILE="mcp-smoke-$$"
SMOKE_URL='data:text/html,<title>MCP%20Bridge%20Host</title><h1>MCP Bridge Host</h1>'

usage() {
  cat <<'USAGE'
Usage: smoke-mcp-bridge.sh [--binary PATH] [--port PORT]

Launches Prometheus with the native agent server, then runs the local
stdio MCP bridge smoke against it.

Options:
  --binary PATH  Browser executable to launch.
  --port PORT    Loopback agent server port. Defaults to 17882.
  --help         Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --binary)
      BINARY="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
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
    "${SOURCE_ROOT}/build/fsb-baseline/bin/prometheus"
  do
    if [ -x "$candidate" ]; then
      BINARY="$candidate"
      break
    fi
  done
fi

if [ -z "$BINARY" ] || [ ! -x "$BINARY" ]; then
  printf 'No executable Prometheus binary found. Pass --binary PATH.\n' >&2
  exit 1
fi

LOG_FILE="${TMPDIR:-/tmp}/prometheus-mcp-smoke.$$.log"
printf 'Launching: %s\n' "$BINARY"
printf 'Agent port: %s\n' "$PORT"
printf 'Smoke log: %s\n' "$LOG_FILE"

PROMETHEUS_AGENT_PORT="$PORT" "$BINARY" --profile "$PROFILE" --no-remote "$SMOKE_URL" >"$LOG_FILE" 2>&1 &
PID="$!"

cleanup() {
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
    wait "$PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if ! curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
  printf 'Agent server did not become healthy.\n' >&2
  sed -n '1,120p' "$LOG_FILE" >&2 || true
  exit 1
fi

PROMETHEUS_AGENT_URL="http://127.0.0.1:${PORT}" node "${SOURCE_ROOT}/tools/prometheus-mcp/smoke.mjs"
printf 'MCP bridge smoke completed.\n'
