#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BINARY=""
PORT="${PROMETHEUS_AGENT_PORT:-17880}"
PROFILE="agent-smoke-$$"
SMOKE_URL='data:text/html,<title>Agent%20Smoke</title><main><h1>Agent Smoke</h1><input id=name><button id=go>Go</button></main>'
AUTH_TOKEN=""

usage() {
  cat <<'USAGE'
Usage: smoke-agent-control.sh [--binary PATH] [--port PORT]

Launches Prometheus with the native agent command server enabled, then
verifies health, tab control, page reads, JavaScript execution, native
surface control, runtime surfaces, typed errors, and audit logging.

Options:
  --binary PATH  Browser executable to launch.
  --port PORT    Loopback agent server port. Defaults to 17880.
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

require_ok() {
  JSON_RESPONSE="$1" EXPECT_TOOL="${2:-}" python3 - <<'PY'
import json
import os
import sys

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
code = (doc.get("error") or {}).get("code")
if doc.get("ok") is not False or code != os.environ["EXPECT_CODE"]:
    raise SystemExit(f"expected error {os.environ['EXPECT_CODE']}, got: {doc}")
PY
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

post_command() {
  curl -fsS \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "http://127.0.0.1:${PORT}/agent/command" \
    --data "$1"
}

LOG_FILE="${TMPDIR:-/tmp}/prometheus-agent-smoke.$$.log"
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
AUDIT_PATH="$(json_field "$HEALTH" "auditPath")"

LIST_RESPONSE="$(post_command '{"id":"list","tool":"list_tabs"}')"
require_ok "$LIST_RESPONSE" "list_tabs"

NEW_TAB_RESPONSE="$(post_command '{"id":"new","tool":"new_tab","params":{"client":"alpha","visual_reason":"Open smoke page","url":"data:text/html,<title>Agent Smoke</title><main><h1>Agent Smoke</h1><input id=name><button id=go>Go</button></main>"}}')"
require_ok "$NEW_TAB_RESPONSE" "new_tab"
TAB_INDEX="$(json_field "$NEW_TAB_RESPONSE" "result.tabIndex")"

sleep 1

READ_RESPONSE="$(post_command "{\"id\":\"read\",\"tool\":\"read_page\",\"params\":{\"tabIndex\":${TAB_INDEX}}}")"
require_ok "$READ_RESPONSE" "read_page"
JSON_RESPONSE="$READ_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if "Agent Smoke" not in doc["result"].get("text", ""):
    raise SystemExit(f"read_page did not include smoke text: {doc}")
PY

JS_RESPONSE="$(post_command "{\"id\":\"js\",\"tool\":\"execute_js\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX},\"code\":\"document.title\"}}")"
require_ok "$JS_RESPONSE" "execute_js"
JSON_RESPONSE="$JS_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if doc["result"].get("value") != "Agent Smoke":
    raise SystemExit(f"execute_js returned unexpected value: {doc}")
PY

DOM_RESPONSE="$(post_command "{\"id\":\"dom\",\"tool\":\"get_dom_snapshot\",\"params\":{\"tabIndex\":${TAB_INDEX}}}")"
require_ok "$DOM_RESPONSE" "get_dom_snapshot"

SNAPSHOT_RESPONSE="$(post_command "{\"id\":\"snapshot\",\"tool\":\"get_page_snapshot\",\"params\":{\"tabIndex\":${TAB_INDEX}}}")"
require_ok "$SNAPSHOT_RESPONSE" "get_page_snapshot"

TYPE_RESPONSE="$(post_command "{\"id\":\"type\",\"tool\":\"type\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX},\"selector\":\"#name\",\"text\":\"Prometheus\",\"visual_reason\":\"Type smoke text\"}}")"
require_ok "$TYPE_RESPONSE" "type"

ATTR_RESPONSE="$(post_command "{\"id\":\"attribute\",\"tool\":\"get_attribute\",\"params\":{\"tabIndex\":${TAB_INDEX},\"selector\":\"#name\",\"attribute\":\"value\"}}")"
require_ok "$ATTR_RESPONSE" "get_attribute"
JSON_RESPONSE="$ATTR_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if doc["result"]["attribute"].get("value") != "Prometheus":
    raise SystemExit(f"get_attribute returned unexpected value: {doc}")
PY

OWNERSHIP_RESPONSE="$(post_command "{\"id\":\"owned\",\"tool\":\"execute_js\",\"params\":{\"client\":\"beta\",\"tabIndex\":${TAB_INDEX},\"code\":\"document.title\"}}")"
require_error_code "$OWNERSHIP_RESPONSE" "TAB_OWNED_BY_OTHER_AGENT"

DIAGNOSTICS_RESPONSE="$(post_command '{"id":"diagnostics","tool":"diagnostics"}')"
require_ok "$DIAGNOSTICS_RESPONSE" "diagnostics"
JSON_RESPONSE="$DIAGNOSTICS_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if doc["result"]["adapters"].get("runtime") is not True:
    raise SystemExit(f"diagnostics did not report runtime adapter: {doc}")
PY

TASK_RESPONSE="$(post_command "{\"id\":\"task\",\"tool\":\"submit_task\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX},\"prompt\":\"Summarize the current Agent Smoke page\"}}")"
require_ok "$TASK_RESPONSE" "submit_task"
TASK_ID="$(json_field "$TASK_RESPONSE" "result.task.id")"
JSON_RESPONSE="$TASK_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
task = doc["result"]["task"]
if task.get("status") != "complete" or not task.get("finalResult"):
    raise SystemExit(f"submit_task did not finish with a final result: {doc}")
if len(task.get("progress", [])) < 3:
    raise SystemExit(f"submit_task did not record progress: {doc}")
PY

TASK_STATUS_RESPONSE="$(post_command "{\"id\":\"task-status\",\"tool\":\"task_status\",\"params\":{\"taskId\":\"${TASK_ID}\"}}")"
require_ok "$TASK_STATUS_RESPONSE" "task_status"

QUEUED_TASK_RESPONSE="$(post_command "{\"id\":\"task-queued\",\"tool\":\"submit_task\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX},\"prompt\":\"Wait for cancellation\",\"run\":false}}")"
require_ok "$QUEUED_TASK_RESPONSE" "submit_task"
QUEUED_TASK_ID="$(json_field "$QUEUED_TASK_RESPONSE" "result.task.id")"
CANCEL_RESPONSE="$(post_command "{\"id\":\"task-cancel\",\"tool\":\"cancel_task\",\"params\":{\"taskId\":\"${QUEUED_TASK_ID}\",\"reason\":\"smoke cancellation\"}}")"
require_ok "$CANCEL_RESPONSE" "cancel_task"
JSON_RESPONSE="$CANCEL_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if doc["result"]["task"].get("status") != "cancelled":
    raise SystemExit(f"cancel_task did not cancel queued task: {doc}")
PY

PROVIDERS_RESPONSE="$(post_command '{"id":"providers","tool":"get_provider_config"}')"
require_ok "$PROVIDERS_RESPONSE" "get_provider_config"
JSON_RESPONSE="$PROVIDERS_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
providers = doc["result"].get("providers", [])
ids = {provider.get("id") for provider in providers}
expected = {"hosted", "routed", "local", "openai", "anthropic", "gemini", "xai", "openrouter", "lmstudio", "custom"}
if not expected.issubset(ids):
    raise SystemExit(f"provider config did not include expected providers: {doc}")
if doc["result"].get("secretTransport") != "native_ui_only":
    raise SystemExit(f"provider config did not mark native-only secret transport: {doc}")
PY

SET_PROVIDER_RESPONSE="$(post_command '{"id":"provider-set","tool":"set_provider_config","params":{"provider":"local","model":"smoke-local","endpoint":"http://127.0.0.1:11434"}}')"
require_ok "$SET_PROVIDER_RESPONSE" "set_provider_config"

SECRET_PROVIDER_RESPONSE="$(post_command '{"id":"provider-secret","tool":"set_provider_config","params":{"provider":"hosted","model":"hosted-smoke","secret":"should-not-cross-transport"}}')"
require_error_code "$SECRET_PROVIDER_RESPONSE" "SECRET_TRANSPORT_BLOCKED"

MEMORY_RESPONSE="$(post_command '{"id":"memory-save","tool":"save_memory","params":{"key":"smoke","text":"runtime memory smoke","url":"https://example.test/"}}')"
require_ok "$MEMORY_RESPONSE" "save_memory"
LIST_MEMORY_RESPONSE="$(post_command '{"id":"memory-list","tool":"list_memory"}')"
require_ok "$LIST_MEMORY_RESPONSE" "list_memory"

GUIDE_RESPONSE="$(post_command '{"id":"guide-save","tool":"save_site_guide","params":{"origin":"https://example.test","instructions":"Prefer structured page reads."}}')"
require_ok "$GUIDE_RESPONSE" "save_site_guide"
LIST_GUIDE_RESPONSE="$(post_command '{"id":"guide-list","tool":"list_site_guides"}')"
require_ok "$LIST_GUIDE_RESPONSE" "list_site_guides"

VAULT_SECRET_RESPONSE="$(post_command '{"id":"vault-secret","tool":"create_vault_entry","params":{"origin":"https://example.test","label":"login","secret":"should-not-cross-transport"}}')"
require_error_code "$VAULT_SECRET_RESPONSE" "SECRET_TRANSPORT_BLOCKED"
VAULT_META_RESPONSE="$(post_command '{"id":"vault-meta","tool":"create_vault_entry","params":{"origin":"https://example.test","label":"login"}}')"
require_ok "$VAULT_META_RESPONSE" "create_vault_entry"
VAULT_LIST_RESPONSE="$(post_command '{"id":"vault-list","tool":"list_vault_entries"}')"
require_ok "$VAULT_LIST_RESPONSE" "list_vault_entries"
VAULT_AUTOFILL_RESPONSE="$(post_command '{"id":"vault-autofill","tool":"vault_autofill","params":{"origin":"https://example.test","label":"login","selector":"#name"}}')"
require_error_code "$VAULT_AUTOFILL_RESPONSE" "VAULT_NATIVE_CONFIRMATION_REQUIRED"

RUNTIME_LOG_RESPONSE="$(post_command '{"id":"runtime-logs","tool":"list_runtime_logs","params":{"limit":5}}')"
require_ok "$RUNTIME_LOG_RESPONSE" "list_runtime_logs"
JSON_RESPONSE="$RUNTIME_LOG_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
if not doc["result"].get("logs"):
    raise SystemExit(f"runtime logs were empty: {doc}")
PY

RUNTIME_DIAGNOSTICS_RESPONSE="$(post_command '{"id":"runtime-diagnostics","tool":"runtime_diagnostics"}')"
require_ok "$RUNTIME_DIAGNOSTICS_RESPONSE" "runtime_diagnostics"

SUPERVISION_RESPONSE="$(post_command "{\"id\":\"supervision-start\",\"tool\":\"start_supervision_session\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX}}}")"
require_ok "$SUPERVISION_RESPONSE" "start_supervision_session"
SUPERVISION_ID="$(json_field "$SUPERVISION_RESPONSE" "result.session.sessionId")"
JSON_RESPONSE="$SUPERVISION_RESPONSE" python3 - <<'PY'
import json
import os
doc = json.loads(os.environ["JSON_RESPONSE"])
snapshot = doc["result"].get("snapshot", {})
session = doc["result"].get("session", {})
if not session.get("pairingCode") or not session.get("sessionId"):
    raise SystemExit(f"supervision session missing pairing fields: {doc}")
if snapshot.get("nodeCount", 0) < 1 or not snapshot.get("hash"):
    raise SystemExit(f"supervision snapshot missing DOM data: {doc}")
PY

SUPERVISION_SNAPSHOT_RESPONSE="$(post_command "{\"id\":\"supervision-snapshot\",\"tool\":\"get_supervision_snapshot\",\"params\":{\"tabIndex\":${TAB_INDEX},\"sessionId\":\"${SUPERVISION_ID}\"}}")"
require_ok "$SUPERVISION_SNAPSHOT_RESPONSE" "get_supervision_snapshot"

SUPERVISION_DIFF_RESPONSE="$(post_command "{\"id\":\"supervision-diff\",\"tool\":\"get_supervision_diff\",\"params\":{\"tabIndex\":${TAB_INDEX},\"sessionId\":\"${SUPERVISION_ID}\"}}")"
require_ok "$SUPERVISION_DIFF_RESPONSE" "get_supervision_diff"

SUPERVISION_STALE_RESPONSE="$(post_command "{\"id\":\"supervision-stale\",\"tool\":\"get_supervision_snapshot\",\"params\":{\"tabIndex\":${TAB_INDEX},\"sessionId\":\"stale-session\"}}")"
require_error_code "$SUPERVISION_STALE_RESPONSE" "STALE_SUPERVISION_SESSION"

SUPERVISION_END_RESPONSE="$(post_command "{\"id\":\"supervision-end\",\"tool\":\"end_supervision_session\",\"params\":{\"sessionId\":\"${SUPERVISION_ID}\"}}")"
require_ok "$SUPERVISION_END_RESPONSE" "end_supervision_session"

LEGACY_RESPONSE="$(post_command '{"id":"legacy","tool":"start_visual_session"}')"
require_error_code "$LEGACY_RESPONSE" "legacy_visual_session_removed"

SURFACE_RESPONSE="$(post_command '{"id":"surface","tool":"open_internal_surface","params":{"surface":"preferences"}}')"
require_ok "$SURFACE_RESPONSE" "open_internal_surface"

AGENT_SURFACE_RESPONSE="$(post_command '{"id":"surface-agent","tool":"open_internal_surface","params":{"surface":"prometheus_agent"}}')"
require_ok "$AGENT_SURFACE_RESPONSE" "open_internal_surface"

ERROR_RESPONSE="$(post_command '{"id":"bad","tool":"definitely_not_supported"}')"
require_error_code "$ERROR_RESPONSE" "unsupported_tool"

CLOSE_RESPONSE="$(post_command "{\"id\":\"close\",\"tool\":\"close_tab\",\"params\":{\"client\":\"alpha\",\"tabIndex\":${TAB_INDEX},\"is_final\":true}}")"
require_ok "$CLOSE_RESPONSE" "close_tab"

if [ ! -s "$AUDIT_PATH" ]; then
  printf 'Expected non-empty audit log at %s\n' "$AUDIT_PATH" >&2
  exit 1
fi

printf 'Agent control smoke completed. Audit log: %s\n' "$AUDIT_PATH"
