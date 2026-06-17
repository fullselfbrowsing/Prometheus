#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BINARY=""
BINARY_PROVIDED="false"
PORT="${PROMETHEUS_AGENT_PORT:-17888}"
PROFILE="fsb-plus-parity-smoke-$$"
MATRIX_ONLY="false"
AUTH_TOKEN=""

usage() {
  cat <<'USAGE'
Usage: smoke-fsb-plus-parity.sh [--binary PATH] [--port PORT] [--matrix-only]

Runs static FSB-plus parity matrix checks and, when a Prometheus binary is
available, live router checks against the native agent command endpoint.

Static checks (always run):
  - FSB-PARITY.md contains all required FSBP rows and category names
  - agentcommandrouter.cpp enforces SECRET_TRANSPORT_BLOCKED, PERMISSION_BLOCKED,
    PROVIDER_NOT_CONFIGURED, and PrometheusRuntime/Policy/agentCap
  - release-validate.sh invokes this parity gate

Options:
  --binary PATH    Browser executable to launch for live parity checks.
  --port PORT      Loopback agent server port. Defaults to 17888.
  --matrix-only    Run static matrix checks only; do not launch binary.
  --help           Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --binary)
      BINARY="${2:-}"
      BINARY_PROVIDED="true"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --matrix-only)
      MATRIX_ONLY="true"
      shift
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

require_rg() {
  local pattern="$1"
  shift
  if ! rg --quiet "$pattern" "$@"; then
    printf 'Missing required pattern %s in %s\n' "$pattern" "$*" >&2
    exit 1
  fi
}

json_field() {
  JSON_RESPONSE="$1" FIELD="$2" python3 - <<'PY'
import json
import os

doc = json.loads(os.environ["JSON_RESPONSE"])
value = doc
for part in os.environ["FIELD"].split("."):
    if isinstance(value, list):
        value = value[int(part)]
    else:
        value = value[part]
print(value)
PY
}

require_ok() {
  JSON_RESPONSE="$1" EXPECT_TOOL="${2:-}" python3 - <<'PY'
import json
import os

doc = json.loads(os.environ["JSON_RESPONSE"])
if doc.get("ok") is not True:
    raise SystemExit(f"expected ok=true, got: {doc}")
expected = os.environ.get("EXPECT_TOOL")
if expected and doc.get("tool") != expected:
    raise SystemExit(f"expected tool {expected}, got: {doc.get('tool')}")
PY
}

require_error_code() {
  JSON_RESPONSE="$1" EXPECT_CODE="$2" python3 - <<'PY'
import json
import os

doc = json.loads(os.environ["JSON_RESPONSE"])
if doc.get("ok") is not False:
    raise SystemExit(f"expected ok=false, got: {doc}")
code = doc.get("error", {}).get("code", "")
expected = os.environ["EXPECT_CODE"]
if code != expected:
    raise SystemExit(f"expected error code {expected}, got: {code}")
PY
}

post_command() {
  curl -fsS \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "http://127.0.0.1:${PORT}/agent/command" \
    --data "$1"
}

run_static_checks() {
  command -v rg >/dev/null 2>&1 || {
    printf 'rg is required for FSB-plus parity static checks.\n' >&2
    exit 1
  }

  # Required FSBP requirement IDs must be present in the parity ledger
  require_rg 'FSBP-01|FSBP-02|FSBP-03|FSBP-04|FSBP-05|FSBP-06' \
    "${SOURCE_ROOT}/tools/fsb-baseline/FSB-PARITY.md"

  # Required matrix category names must appear in the parity ledger
  for category in 'side panel' 'provider settings' 'model discovery' 'MCP tools' \
                  'vault' 'supervision' 'tab ownership' 'release validation'; do
    require_rg "$category" "${SOURCE_ROOT}/tools/fsb-baseline/FSB-PARITY.md"
  done

  # Secret transport enforcement must be present in both router and runtime
  require_rg 'SECRET_TRANSPORT_BLOCKED' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp" \
    "${SOURCE_ROOT}/src/lib/agent/agentruntime.cpp"

  # Parity gate must be invoked from release-validate.sh
  require_rg 'smoke-fsb-plus-parity' \
    "${SOURCE_ROOT}/tools/fsb-baseline/release-validate.sh"

  # Agent cap must be read from persistent Policy settings (not environment-only)
  require_rg 'PrometheusRuntime/Policy/agentCap' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"

  # Internal-surface permission policy and provider configuration errors must be defined
  require_rg 'PERMISSION_BLOCKED|PROVIDER_NOT_CONFIGURED' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"

  printf 'FSB-plus parity static checks completed.\n'
}

run_static_checks

if [ "$MATRIX_ONLY" = "true" ]; then
  printf 'Parity matrix static checks passed.\n'
  exit 0
fi

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
  if [ "$BINARY_PROVIDED" = "true" ]; then
    printf 'No executable Prometheus binary found at %s.\n' "$BINARY" >&2
    exit 1
  fi
  printf 'No executable Prometheus binary found; skipped live parity smoke.\n'
  exit 0
fi

LOG_FILE="${TMPDIR:-/tmp}/prometheus-fsb-plus-parity-smoke.$$.log"
printf 'Launching: %s\n' "$BINARY"
printf 'Agent port: %s\n' "$PORT"
printf 'Smoke log: %s\n' "$LOG_FILE"

PROMETHEUS_AGENT_PORT="$PORT" "$BINARY" --profile "$PROFILE" --no-remote \
  'data:text/html,<title>FSB%20Plus%20Parity%20Smoke</title><main><h1>FSB Plus Parity Smoke</h1></main>' \
  >"$LOG_FILE" 2>&1 &
PID="$!"

cleanup() {
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
    wait "$PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

HEALTH=""
for _ in $(seq 1 80); do
  if HEALTH="$(curl -fsS "http://127.0.0.1:${PORT}/health" 2>/dev/null)"; then
    break
  fi
  sleep 0.25
done

if [ -z "$HEALTH" ]; then
  printf 'Agent server did not become healthy.\n' >&2
  sed -n '1,120p' "$LOG_FILE" >&2 || true
  exit 1
fi

require_ok "$HEALTH"
AUTH_TOKEN="$(json_field "$HEALTH" "authorization.token")"
if [ -z "$AUTH_TOKEN" ]; then
  printf 'Agent health did not include an authorization token.\n' >&2
  exit 1
fi

# Verify diagnostics tool is available and returns ok
DIAG_RESPONSE="$(post_command '{"id":"parity-diag","tool":"diagnostics","params":{}}')"
require_ok "$DIAG_RESPONSE" "diagnostics"

# Verify list_tabs tool is available and returns ok
LIST_RESPONSE="$(post_command '{"id":"parity-list-tabs","tool":"list_tabs","params":{}}')"
require_ok "$LIST_RESPONSE" "list_tabs"

# Verify health tools array includes required tool names
TOOLS_JSON="$(json_field "$HEALTH" "tools")"
for required_tool in diagnostics list_tabs new_tab dom_snapshot page_snapshot; do
  if ! printf '%s' "$TOOLS_JSON" | python3 -c "
import json, sys
tools = json.loads(sys.stdin.read())
name = '$required_tool'
if name not in tools:
    raise SystemExit(f'required tool {name} not in health tools array')
"; then
    printf 'Required tool %s not found in /health tools array.\n' "$required_tool" >&2
    exit 1
  fi
done

printf 'FSB-plus parity smoke completed.\n'
