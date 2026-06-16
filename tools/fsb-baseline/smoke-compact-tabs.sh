#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BINARY=""
BINARY_PROVIDED="false"
PORT="${PROMETHEUS_AGENT_PORT:-17887}"
PROFILE="compact-tabs-smoke-$$"
SMOKE_URL='data:text/html,<title>Compact%20Tabs%20Smoke</title><main><h1>Compact Tabs Smoke</h1></main>'
AUTH_TOKEN=""

usage() {
  cat <<'USAGE'
Usage: smoke-compact-tabs.sh [--binary PATH] [--port PORT]

Runs static compact tab, grouped search, and agent-aware tab state checks.
When a Prometheus binary is available, launches it and verifies list_tabs
returns compact layout state fields for owned and supervised tabs.

Options:
  --binary PATH  Browser executable to launch for live list_tabs checks.
  --port PORT    Loopback agent server port. Defaults to 17887.
  --help         Show this help.
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

run_static_checks() {
  command -v rg >/dev/null 2>&1 || {
    printf 'rg is required for compact tab static checks.\n' >&2
    exit 1
  }

  require_rg 'tabLayout|tabDisplay|TitleAndIcon|FaviconOnly|Compact|Separate' \
    "${SOURCE_ROOT}/src/lib/other/qzsettings.cpp" \
    "${SOURCE_ROOT}/src/lib/preferences/preferences.cpp" \
    "${SOURCE_ROOT}/src/lib/preferences/preferences.ui"
  require_rg 'CompactTabStrip|compact-tabs|locationBars' \
    "${SOURCE_ROOT}/src/lib/navigation/navigationbar.cpp" \
    "${SOURCE_ROOT}/src/lib/tabwidget/compacttabstrip.cpp"
  require_rg 'TabSearchPopup|Tab Overview|Search Tabs' \
    "${SOURCE_ROOT}/src/lib/app/browserwindow.cpp" \
    "${SOURCE_ROOT}/src/lib/navigation/navigationbar.cpp" \
    "${SOURCE_ROOT}/src/lib/tabwidget/tabsearchpopup.cpp"
  require_rg 'TabGroupIdRole|TabGroupNameRole|TabGroupCollapsedRole|setGroupFilter|Ungrouped' \
    "${SOURCE_ROOT}/src/lib/tabwidget/compacttabfiltermodel.cpp" \
    "${SOURCE_ROOT}/src/lib/tabwidget/compacttabdelegate.cpp" \
    "${SOURCE_ROOT}/src/lib/tabwidget/tabsearchfiltermodel.cpp" \
    "${SOURCE_ROOT}/src/lib/tabwidget/tabsearchpopup.cpp" \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"
  require_rg 'owner|activeAutomation|supervisionActive|health|groupId|groupName|groupCollapsed' \
    "${SOURCE_ROOT}/src/lib/agent/agentcommandrouter.cpp"

  printf 'Compact tab static checks completed.\n'
}

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

require_list_tab_fields() {
  JSON_RESPONSE="$1" TARGET_TAB_INDEX="${2:-}" EXPECT_OWNER="${3:-}" EXPECT_SUPERVISION="${4:-}" python3 - <<'PY'
import json
import os

doc = json.loads(os.environ["JSON_RESPONSE"])
windows = doc.get("result", {}).get("windows", [])
tabs = [tab for window in windows for tab in window.get("tabs", [])]
if not tabs:
    raise SystemExit(f"list_tabs returned no tabs: {doc}")

required = [
    "owner",
    "activeAutomation",
    "supervisionActive",
    "health",
    "groupId",
    "groupName",
    "groupCollapsed",
]
for tab in tabs:
    missing = [field for field in required if field not in tab]
    if missing:
        raise SystemExit(f"tab missing fields {missing}: {tab}")
    if not isinstance(tab.get("activeAutomation"), bool):
        raise SystemExit(f"activeAutomation is not boolean: {tab}")
    if not isinstance(tab.get("supervisionActive"), bool):
        raise SystemExit(f"supervisionActive is not boolean: {tab}")
    if not isinstance(tab.get("groupCollapsed"), bool):
        raise SystemExit(f"groupCollapsed is not boolean: {tab}")
    if not isinstance(tab.get("health"), str) or not tab.get("health"):
        raise SystemExit(f"health is not a non-empty string: {tab}")

target_index = os.environ.get("TARGET_TAB_INDEX")
if not target_index:
    raise SystemExit(0)

target = None
for tab in tabs:
    if str(tab.get("tabIndex")) == target_index:
        target = tab
        break
if target is None:
    raise SystemExit(f"target tab {target_index} not found in list_tabs: {doc}")

expected_owner = os.environ.get("EXPECT_OWNER")
if expected_owner and target.get("owner") != expected_owner:
    raise SystemExit(f"expected owner {expected_owner}, got {target}")

expected_supervision = os.environ.get("EXPECT_SUPERVISION")
if expected_supervision:
    expected = expected_supervision == "true"
    if target.get("supervisionActive") is not expected:
        raise SystemExit(f"expected supervisionActive={expected}, got {target}")
PY
}

post_command() {
  curl -fsS \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "http://127.0.0.1:${PORT}/agent/command" \
    --data "$1"
}

run_static_checks

if [ -z "$BINARY" ] || [ ! -x "$BINARY" ]; then
  if [ "$BINARY_PROVIDED" = "true" ]; then
    printf 'No executable Prometheus binary found at %s.\n' "$BINARY" >&2
    exit 1
  fi
  printf 'No executable Prometheus binary found; skipped live compact tab smoke.\n'
  exit 0
fi

LOG_FILE="${TMPDIR:-/tmp}/prometheus-compact-tabs-smoke.$$.log"
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

LIST_RESPONSE="$(post_command '{"id":"compact-list-initial","tool":"list_tabs"}')"
require_ok "$LIST_RESPONSE" "list_tabs"
require_list_tab_fields "$LIST_RESPONSE"

NEW_TAB_RESPONSE="$(post_command '{"id":"compact-new","tool":"new_tab","params":{"client":"compact-smoke","visual_reason":"Open compact tab smoke page","url":"data:text/html,<title>Compact Tabs Owned</title><main><h1>Owned Compact Tab</h1></main>"}}')"
require_ok "$NEW_TAB_RESPONSE" "new_tab"
TAB_INDEX="$(json_field "$NEW_TAB_RESPONSE" "result.tabIndex")"
AGENT_ID="$(json_field "$NEW_TAB_RESPONSE" "result.agentId")"

sleep 1

OWNED_LIST_RESPONSE="$(post_command '{"id":"compact-list-owned","tool":"list_tabs"}')"
require_ok "$OWNED_LIST_RESPONSE" "list_tabs"
require_list_tab_fields "$OWNED_LIST_RESPONSE" "$TAB_INDEX" "$AGENT_ID"

SUPERVISION_RESPONSE="$(post_command "{\"id\":\"compact-supervision-start\",\"tool\":\"start_supervision_session\",\"params\":{\"client\":\"compact-smoke\",\"tabIndex\":${TAB_INDEX}}}")"
require_ok "$SUPERVISION_RESPONSE" "start_supervision_session"
SUPERVISION_ID="$(json_field "$SUPERVISION_RESPONSE" "result.session.sessionId")"

SUPERVISED_LIST_RESPONSE="$(post_command '{"id":"compact-list-supervised","tool":"list_tabs"}')"
require_ok "$SUPERVISED_LIST_RESPONSE" "list_tabs"
require_list_tab_fields "$SUPERVISED_LIST_RESPONSE" "$TAB_INDEX" "$AGENT_ID" "true"

SUPERVISION_END_RESPONSE="$(post_command "{\"id\":\"compact-supervision-end\",\"tool\":\"end_supervision_session\",\"params\":{\"sessionId\":\"${SUPERVISION_ID}\"}}")"
require_ok "$SUPERVISION_END_RESPONSE" "end_supervision_session"

ENDED_LIST_RESPONSE="$(post_command '{"id":"compact-list-ended","tool":"list_tabs"}')"
require_ok "$ENDED_LIST_RESPONSE" "list_tabs"
require_list_tab_fields "$ENDED_LIST_RESPONSE" "$TAB_INDEX" "$AGENT_ID" "false"

CLOSE_RESPONSE="$(post_command "{\"id\":\"compact-close\",\"tool\":\"close_tab\",\"params\":{\"client\":\"compact-smoke\",\"tabIndex\":${TAB_INDEX},\"is_final\":true}}")"
require_ok "$CLOSE_RESPONSE" "close_tab"

printf 'Compact tab smoke completed.\n'
