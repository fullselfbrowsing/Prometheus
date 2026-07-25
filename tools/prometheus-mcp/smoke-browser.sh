#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROMETHEUS_BIN="${PROJECT_ROOT}/.context/chromium/src/out/Default/Prometheus.app/Contents/MacOS/Prometheus"
FOCUSED_BLINK_DIR="${PROJECT_ROOT}/.context/chromium/src/out/Default/phase21-focused/blink-modules"
FIXTURE_ENTRY="${SCRIPT_DIR}/test/fixture-server.mjs"
SMOKE_CLIENT="${SCRIPT_DIR}/test/smoke-client.mjs"
BRIDGE_ENTRY="${SCRIPT_DIR}/bin/prometheus-mcp.mjs"

SMOKE_TIMEOUT_SECONDS=120
DESCRIPTOR_WAIT_SECONDS=20
FIXTURE_WAIT_SECONDS=10

fail() {
  printf 'prometheus MCP live smoke failed: %s\n' "$1" >&2
  exit 1
}

[ -x "${PROMETHEUS_BIN}" ] || fail 'built Prometheus app is unavailable'
[ -s "${FOCUSED_BLINK_DIR}/libblink_modules.dylib" ] \
  || fail 'focused supervision Blink module is unavailable'
NODE_BIN="$(command -v node)" || fail 'Node.js is unavailable'

umask 077
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/prometheus-mcp-live.XXXXXX")"
TEMP_ROOT="$(cd "${TEMP_ROOT}" && pwd -P)"
PROFILE_DIR="${TEMP_ROOT}/profile"
CAPTURE_DIR="${TEMP_ROOT}/capture"
DESCRIPTOR_FILE="${TEMP_ROOT}/endpoint.json"
FIXTURE_READY_FILE="${TEMP_ROOT}/fixture.json"
PROVIDER_BOOTSTRAP_FILE="${TEMP_ROOT}/provider-bootstrap.json"
SUPERVISION_BOOTSTRAP_FILE="${TEMP_ROOT}/supervision-bootstrap.json"
DENYLIST_FILE="${TEMP_ROOT}/private-denylist.json"
BROWSER_STDOUT="${TEMP_ROOT}/browser.stdout.log"
BROWSER_STDERR="${TEMP_ROOT}/browser.stderr.log"
FIXTURE_STDOUT="${TEMP_ROOT}/fixture.stdout.log"
FIXTURE_STDERR="${TEMP_ROOT}/fixture.stderr.log"
CLIENT_STDOUT="${TEMP_ROOT}/client.stdout.log"
CLIENT_STDERR="${TEMP_ROOT}/client.stderr.log"
mkdir -m 700 "${PROFILE_DIR}" "${CAPTURE_DIR}"

START_SECONDS="${SECONDS}"
DEADLINE_SECONDS=$((START_SECONDS + SMOKE_TIMEOUT_SECONDS))
recorded_pids=()

record_pid() {
  local candidate="$1"
  local recorded
  [ -n "${candidate}" ] || return 0
  for recorded in "${recorded_pids[@]:-}"; do
    [ "${recorded}" = "${candidate}" ] && return 0
  done
  recorded_pids+=("${candidate}")
}

record_descendants() {
  local parent_pid="$1"
  local child_pid
  while IFS= read -r child_pid; do
    [ -n "${child_pid}" ] || continue
    record_descendants "${child_pid}"
    record_pid "${child_pid}"
  done < <(pgrep -P "${parent_pid}" 2>/dev/null || true)
}

cleanup() {
  local pid
  local index
  for pid in "${recorded_pids[@]:-}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      record_descendants "${pid}"
    fi
  done
  for ((index=${#recorded_pids[@]} - 1; index >= 0; index--)); do
    pid="${recorded_pids[index]}"
    kill -TERM "${pid}" 2>/dev/null || true
  done
  local stop_deadline=$((SECONDS + 5))
  while [ "${SECONDS}" -lt "${stop_deadline}" ]; do
    local alive=false
    for pid in "${recorded_pids[@]:-}"; do
      if kill -0 "${pid}" 2>/dev/null; then
        alive=true
        break
      fi
    done
    [ "${alive}" = false ] && break
    sleep 0.1
  done
  for ((index=${#recorded_pids[@]} - 1; index >= 0; index--)); do
    pid="${recorded_pids[index]}"
    kill -KILL "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
  done
  rm -rf "${TEMP_ROOT}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

deadline_guard() {
  [ "${SECONDS}" -lt "${DEADLINE_SECONDS}" ] || fail '120-second outer timeout expired'
}

wait_for_file() {
  local file="$1"
  local seconds="$2"
  local owner_pid="$3"
  local local_deadline=$((SECONDS + seconds))
  while [ ! -s "${file}" ]; do
    deadline_guard
    kill -0 "${owner_pid}" 2>/dev/null || fail 'required child exited before readiness'
    [ "${SECONDS}" -lt "${local_deadline}" ] || return 1
    sleep 0.1
  done
}

PROMETHEUS_MCP_FIXTURE_READY_FILE="${FIXTURE_READY_FILE}" \
PROMETHEUS_MCP_FIXTURE_PROVIDER_DELAY_MS=5000 \
  "${NODE_BIN}" "${FIXTURE_ENTRY}" >"${FIXTURE_STDOUT}" 2>"${FIXTURE_STDERR}" &
FIXTURE_PID="$!"
record_pid "${FIXTURE_PID}"
wait_for_file "${FIXTURE_READY_FILE}" "${FIXTURE_WAIT_SECONDS}" "${FIXTURE_PID}" \
  || fail 'fixture did not become ready'

FIXTURE_URL="$(${NODE_BIN} -e '
  const fs = require("node:fs");
  const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  if (typeof value.url !== "string" || !/^http:\/\/(?:127\.0\.0\.1|\[::1\]):[0-9]+\/$/.test(value.url)) process.exit(1);
  process.stdout.write(value.url);
' "${FIXTURE_READY_FILE}")" || fail 'fixture readiness document is invalid'

"${NODE_BIN}" - "${FIXTURE_READY_FILE}" "${PROVIDER_BOOTSTRAP_FILE}" <<'NODE' \
  || fail 'provider bootstrap document is invalid'
const fs = require('node:fs');
const path = require('node:path');

const [readyFile, bootstrapFile] = process.argv.slice(2);
const ready = JSON.parse(fs.readFileSync(readyFile, 'utf8'));
if (!path.isAbsolute(bootstrapFile)
    || typeof ready.origin !== 'string'
    || !/^http:\/\/(?:127\.0\.0\.1|\[::1\]):[0-9]+$/.test(ready.origin)) {
  process.exit(1);
}
const config = {
  schema_version: 1,
  provider_id: 'phase20-smoke-local',
  kind: 'lm_studio',
  route: 'local',
  endpoint: `${ready.origin}/v1/`,
  model: 'phase20-fixture-model',
  enabled: true,
};
const descriptor = fs.openSync(bootstrapFile, 'wx', 0o600);
try {
  fs.writeFileSync(descriptor, JSON.stringify(config), 'utf8');
  fs.fsyncSync(descriptor);
} finally {
  fs.closeSync(descriptor);
}
fs.chmodSync(bootstrapFile, 0o600);
const metadata = fs.lstatSync(bootstrapFile);
const observed = JSON.parse(fs.readFileSync(bootstrapFile, 'utf8'));
if (!metadata.isFile() || metadata.isSymbolicLink()
    || (metadata.mode & 0o777) !== 0o600
    || Object.keys(observed).sort().join(',')
      !== 'enabled,endpoint,kind,model,provider_id,route,schema_version'
    || observed.schema_version !== 1
    || observed.provider_id !== 'phase20-smoke-local'
    || observed.kind !== 'lm_studio'
    || observed.route !== 'local'
    || observed.endpoint !== `${ready.origin}/v1/`
    || observed.model !== 'phase20-fixture-model'
    || observed.enabled !== true) {
  process.exit(1);
}
NODE

SUPERVISION_CHALLENGE="$("${NODE_BIN}" - "${FIXTURE_READY_FILE}" \
  "${SUPERVISION_BOOTSTRAP_FILE}" <<'NODE'
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const [readyFile, bootstrapFile] = process.argv.slice(2);
const ready = JSON.parse(fs.readFileSync(readyFile, 'utf8'));
if (!path.isAbsolute(bootstrapFile)
    || typeof ready.origin !== 'string'
    || !/^http:\/\/(?:127\.0\.0\.1|\[::1\]):[0-9]+$/.test(ready.origin)) {
  process.exit(1);
}
const challengeBuffer = crypto.randomBytes(32);
const challenge = challengeBuffer.toString('hex');
challengeBuffer.fill(0);
const config = {
  schema_version: 1,
  challenge,
  expected_origin: ready.origin,
  pairing_slots: 2,
  dialog_responses: ['enable_control:accept', 'remote_action:accept'],
};
const descriptor = fs.openSync(bootstrapFile, 'wx', 0o600);
try {
  fs.writeFileSync(descriptor, JSON.stringify(config), 'utf8');
  fs.fsyncSync(descriptor);
} finally {
  fs.closeSync(descriptor);
}
fs.chmodSync(bootstrapFile, 0o600);
const metadata = fs.lstatSync(bootstrapFile);
const observed = JSON.parse(fs.readFileSync(bootstrapFile, 'utf8'));
if (!metadata.isFile() || metadata.isSymbolicLink()
    || (metadata.mode & 0o777) !== 0o600
    || Object.keys(observed).sort().join(',')
      !== 'challenge,dialog_responses,expected_origin,pairing_slots,schema_version'
    || observed.schema_version !== 1
    || observed.challenge !== challenge
    || !/^[0-9a-f]{64}$/.test(observed.challenge)
    || observed.expected_origin !== ready.origin
    || observed.pairing_slots !== 2
    || JSON.stringify(observed.dialog_responses)
      !== '["enable_control:accept","remote_action:accept"]') {
  process.exit(1);
}
process.stdout.write(challenge);
NODE
)" || fail 'supervision bootstrap document is invalid'
[ "${#SUPERVISION_CHALLENGE}" -eq 64 ] \
  || fail 'supervision challenge generation failed'

BROWSER_ARGS=(
  "--user-data-dir=${PROFILE_DIR}"
  --test-type=prometheus-runtime
  "--prometheus-runtime-test-provider-config=${PROVIDER_BOOTSTRAP_FILE}"
  "--prometheus-supervision-test-bootstrap=${SUPERVISION_BOOTSTRAP_FILE}"
  --no-first-run
  --no-default-browser-check
  --no-proxy-server
  # Match Chromium's macOS test launcher for a fresh disposable profile:
  # chrome/test/base/test_launcher_utils.cc initializes OS crypt this way.
  --use-mock-keychain
  # The browser-test-only loopback fixture must not depend on host LNA grants.
  # See services/network/public/cpp/features.cc and net/base/features.cc.
  --disable-features=DialMediaRouteProvider,LocalNetworkAccessChecks,LocalNetworkPermissionCheck
  --new-window
  "--prometheus-agent-endpoint-descriptor=${DESCRIPTOR_FILE}"
  "${FIXTURE_URL}"
)
MAC_CHROMIUM_TMPDIR="${TEMP_ROOT}" \
DYLD_LIBRARY_PATH="${FOCUSED_BLINK_DIR}${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}" \
  "${PROMETHEUS_BIN}" "${BROWSER_ARGS[@]}" \
  >"${BROWSER_STDOUT}" 2>"${BROWSER_STDERR}" &
BROWSER_LAUNCH_PID="$!"
record_pid "${BROWSER_LAUNCH_PID}"
wait_for_file "${DESCRIPTOR_FILE}" "${DESCRIPTOR_WAIT_SECONDS}" "${BROWSER_LAUNCH_PID}" \
  || fail 'endpoint descriptor did not become ready in 20 seconds'
BROWSER_PID="$(${NODE_BIN} -e '
  const fs = require("node:fs");
  const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  if (!Number.isSafeInteger(value.pid) || value.pid <= 0) process.exit(1);
  process.stdout.write(String(value.pid));
' "${DESCRIPTOR_FILE}")" || fail 'endpoint descriptor browser pid is invalid'
record_pid "${BROWSER_PID}"
kill -0 "${BROWSER_PID}" 2>/dev/null || fail 'descriptor browser pid is not live'

if [ "$(stat -f '%Lp' "${DESCRIPTOR_FILE}" 2>/dev/null || stat -c '%a' "${DESCRIPTOR_FILE}" 2>/dev/null)" != '600' ]; then
  fail 'descriptor mode is not 0600'
fi

PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR="${DESCRIPTOR_FILE}" \
PROMETHEUS_MCP_FIXTURE_URL="${FIXTURE_URL}" \
PROMETHEUS_MCP_SMOKE_CAPTURE_DIR="${CAPTURE_DIR}" \
PROMETHEUS_MCP_SMOKE_DENYLIST_FILE="${DENYLIST_FILE}" \
PROMETHEUS_MCP_SMOKE_PROFILE_PATH="${PROFILE_DIR}" \
PROMETHEUS_MCP_SMOKE_SUPERVISION_CHALLENGE="${SUPERVISION_CHALLENGE}" \
PROMETHEUS_MCP_BRIDGE_ENTRY="${BRIDGE_ENTRY}" \
  "${NODE_BIN}" "${SMOKE_CLIENT}" >"${CLIENT_STDOUT}" 2>"${CLIENT_STDERR}" &
CLIENT_PID="$!"
record_pid "${CLIENT_PID}"

client_is_running() {
  local running_pid
  while IFS= read -r running_pid; do
    [ "${running_pid}" = "${CLIENT_PID}" ] && return 0
  done < <(jobs -pr)
  return 1
}

while client_is_running; do
  deadline_guard
  kill -0 "${BROWSER_PID}" 2>/dev/null || fail 'browser exited during live RPCs'
  kill -0 "${FIXTURE_PID}" 2>/dev/null || fail 'fixture exited during live RPCs'
  sleep 0.1
done
set +e
wait "${CLIENT_PID}"
CLIENT_STATUS="$?"
set -e
if [ "${CLIENT_STATUS}" -ne 0 ]; then
  CLIENT_FAILURE_STAGE="$("${NODE_BIN}" -e '
    const fs = require("node:fs");
    const text = fs.readFileSync(process.argv[1], "utf8").trim();
    const match = /^prometheus-mcp smoke client: live smoke failed at ([a-z0-9_]+)$/.exec(text);
    process.stdout.write(match?.[1] ?? "unknown");
  ' "${CLIENT_STDERR}")"
  fail "independent stdio client failed at ${CLIENT_FAILURE_STAGE}"
fi
deadline_guard

"${NODE_BIN}" - "${CLIENT_STDOUT}" "${CLIENT_STDERR}" "${DENYLIST_FILE}" \
  "${BROWSER_STDOUT}" "${BROWSER_STDERR}" "${FIXTURE_STDOUT}" \
  "${FIXTURE_STDERR}" "${CAPTURE_DIR}" <<'NODE' \
  || fail 'captured output or protocol metadata failed validation'
const fs = require('node:fs');
const path = require('node:path');

const [resultFile, clientErrorFile, denylistFile, ...roots] = process.argv.slice(2);
const resultText = fs.readFileSync(resultFile, 'utf8');
const lines = resultText.trim().split('\n');
if (lines.length !== 1) process.exit(1);
const result = JSON.parse(lines[0]);
if (result.ok !== true || result.tools !== 90 || result.diagnostics !== 10
    || result.runtime_flows !== true
    || result.caller_isolation !== true
    || result.provider_bootstrap !== true
    || result.provider_mutation_denied !== true
    || result.vault_confirmation_only !== true
    || result.background_focus_preserved !== true
    || result.ownership_denied !== true
    || result.resume_proven !== true
    || result.expiry_released !== true
    || result.close_released !== true
    || result.supervision_two_viewers !== true
    || result.supervision_shared_hub !== true
    || result.supervision_actions !== true
    || result.supervision_resync !== true
    || result.supervision_cleanup !== true
    || result.supervision_compatibility_private !== true) process.exit(1);

const denied = JSON.parse(fs.readFileSync(denylistFile, 'utf8'));
if (!Array.isArray(denied) || denied.length < 15) process.exit(1);
const files = [resultFile, clientErrorFile];
for (const root of roots) {
  const metadata = fs.statSync(root);
  if (metadata.isDirectory()) {
    for (const name of fs.readdirSync(root)) files.push(path.join(root, name));
  } else {
    files.push(root);
  }
}
for (const file of files) {
  const text = fs.readFileSync(file, 'utf8');
  for (const value of denied) {
    if (typeof value === 'string' && value.length > 0 && text.includes(value)) process.exit(1);
  }
  if (file.endsWith('.protocol.jsonl')) {
    for (const line of text.trim().split('\n').filter(Boolean)) {
      const frame = JSON.parse(line);
      const keys = Object.keys(frame).sort().join(',');
      if (frame.jsonrpc !== '2.0' || !Number.isSafeInteger(frame.id)
          || !['error', 'result'].includes(frame.kind)
          || typeof frame.method !== 'string'
          || keys !== 'id,jsonrpc,kind,method') process.exit(1);
    }
  }
}
NODE

printf 'Prometheus MCP live smoke passed.\n'
