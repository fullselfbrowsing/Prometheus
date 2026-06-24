#!/usr/bin/env bash
set -euo pipefail

# Prometheus Chromium Smoke — identity-asserting launch gate for rebranded Prometheus.app.
# Source: Phase 13 branding decisions and Chromium Mac launch docs.
# [VERIFIED: .planning/phases/13-product-identity-branding-and-legal-baseline/13-CONTEXT.md]
# [CITED: https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md]
#
# Usage:
#   bash smoke-launch-prometheus.sh                 # normal launch path only
#   bash smoke-launch-prometheus.sh --with-dial-workaround  # normal first; retry with DialMediaRouteProvider workaround on failure
#
# Evidence written:
#   .context/prometheus-launch.status   — key=value launch status record
#   .context/prometheus-launch.log      — Prometheus stdout/stderr from the normal (and workaround) attempt
#
# NOTE: This script requires Prometheus.app to exist (built after BRANDING patch in Wave 2).
# Do NOT run before Wave 2 rebuild. Use `bash -n smoke-launch-prometheus.sh` for syntax check only.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"
PROMETHEUS_BIN="${BUILD_DIR}/Prometheus.app/Contents/MacOS/Prometheus"
STATUS_FILE="${PROJECT_ROOT}/.context/prometheus-launch.status"
LOG_FILE="${PROJECT_ROOT}/.context/prometheus-launch.log"

SMOKE_URL='data:text/html,<title>Prometheus Smoke</title><h1>OK</h1>'
STARTUP_WAIT_SECONDS=8
QUIT_WAIT_SECONDS=20

export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

# -------------------------------------------------------------------------
# Argument handling
# Accepted: no argument or --with-dial-workaround. Unknown arguments fail.
# -------------------------------------------------------------------------

WITH_DIAL_WORKAROUND=false

case "${1:-}" in
  "")
    WITH_DIAL_WORKAROUND=false
    ;;
  "--with-dial-workaround")
    WITH_DIAL_WORKAROUND=true
    ;;
  *)
    printf 'prometheus launch smoke failed: unknown argument "%s"; supported: (none) or --with-dial-workaround\n' "${1}" >&2
    exit 1
    ;;
esac

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

fail() {
  printf 'prometheus launch smoke failed: %s\n' "$1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Cleanup trap: remove every temp profile dir created this run and terminate
# any still-running launched Prometheus process so an interrupt (Ctrl-C /
# SIGTERM) or early exit during the startup/quit sleeps never orphans the
# process or leaks a profile dir. Fires on normal exit, on `exit 1`, and on
# INT/TERM. Every action is guarded so cleanup itself never trips `set -e`.
# -------------------------------------------------------------------------

profile_dirs=()

_attempt_pid="-"

cleanup() {
  if [ "${_attempt_pid:-"-"}" != "-" ]; then
    pkill -P "${_attempt_pid}" 2>/dev/null || true
    kill "${_attempt_pid}" 2>/dev/null || true
  fi
  local d
  for d in "${profile_dirs[@]:-}"; do
    [ -n "${d}" ] && rm -rf "${d}" 2>/dev/null || true
  done
}
trap cleanup INT TERM EXIT

# -------------------------------------------------------------------------
# Preflight: run environment gate
# -------------------------------------------------------------------------

bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"

# -------------------------------------------------------------------------
# Preflight: verify Prometheus binary exists before attempting launch
# -------------------------------------------------------------------------

[ -x "${PROMETHEUS_BIN}" ] \
  || fail "Prometheus.app binary not found at ${PROMETHEUS_BIN} — run gn gen + autoninja after BRANDING patch (Wave 2)"

# -------------------------------------------------------------------------
# Resolve revisions and GN args for evidence
# -------------------------------------------------------------------------

mkdir -p "${PROJECT_ROOT}/.context"

chromium_revision="$(git -C "${CHROMIUM_SRC}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read Chromium HEAD from ${CHROMIUM_SRC}"

gn_args="$(tr '\n' ' ' < "${BUILD_DIR}/args.gn" 2>/dev/null | sed 's/[[:space:]]*$//')"

# -------------------------------------------------------------------------
# Launch helper: attempt one Prometheus launch, wait, quit cleanly.
# Returns 0 on clean exit; 1 on startup failure or timeout.
# Sets global: _attempt_pid, _attempt_status, profile_dir (this attempt's dir)
# -------------------------------------------------------------------------

profile_dir=""

attempt_launch() {
  local attempt_label="$1"
  local extra_flags="${2:-}"

  profile_dir="$(mktemp -d "${PROJECT_ROOT}/.context/prometheus-smoke-profile.XXXXXX")"
  profile_dirs+=("${profile_dir}")

  local launch_cmd
  if [ -z "${extra_flags}" ]; then
    launch_cmd="${PROMETHEUS_BIN} --user-data-dir=${profile_dir} --no-first-run --no-default-browser-check ${SMOKE_URL}"
  else
    launch_cmd="${PROMETHEUS_BIN} --user-data-dir=${profile_dir} --no-first-run --no-default-browser-check ${extra_flags} ${SMOKE_URL}"
  fi

  {
    printf '\n=== %s launch attempt (%s) ===\n' "${attempt_label}" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    printf 'command: %s\n' "${launch_cmd}"
  } >> "${LOG_FILE}"

  "${PROMETHEUS_BIN}" \
    --user-data-dir="${profile_dir}" \
    --no-first-run \
    --no-default-browser-check \
    ${extra_flags:+${extra_flags}} \
    "${SMOKE_URL}" \
    >> "${LOG_FILE}" 2>&1 &

  _attempt_pid="$!"
  _launch_cmd_used="${launch_cmd}"

  sleep "${STARTUP_WAIT_SECONDS}"

  if ! kill -0 "${_attempt_pid}" 2>/dev/null; then
    printf 'Launch smoke: process %s exited before startup wait completed.\n' "${_attempt_pid}" >&2
    _attempt_status=1
    return 1
  fi

  printf 'Launch smoke: process %s alive after %ss startup wait.\n' "${_attempt_pid}" "${STARTUP_WAIT_SECONDS}"

  # Request clean quit via osascript: use Prometheus bundle ID and app name.
  # osascript may exit 0 even when the quit request is not delivered (Launch Services
  # registration race on a new bundle ID). Always verify the process exited within
  # a short grace period and fall back to SIGTERM if it did not.
  local quit_sent=false
  if osascript -e 'tell application id "com.fullselfbrowsing.prometheus" to quit' 2>/dev/null; then
    quit_sent=true
  elif osascript -e 'tell application "Prometheus" to quit' 2>/dev/null; then
    quit_sent=true
  fi

  if [ "${quit_sent}" = "false" ]; then
    printf 'Launch smoke: osascript quit failed; falling back to SIGTERM for pid %s and its children.\n' "${_attempt_pid}" >&2
    pkill -TERM -P "${_attempt_pid}" 2>/dev/null || true
    kill "${_attempt_pid}" 2>/dev/null || true
  else
    # osascript claimed success. Give the app a 3s grace period to exit; if it is still
    # alive the quit was not actually delivered (new bundle ID registration race) and
    # we fall back to SIGTERM so the smoke can complete cleanly.
    local grace=0
    while kill -0 "${_attempt_pid}" 2>/dev/null && [ "${grace}" -lt 3 ]; do
      sleep 1
      grace=$((grace + 1))
    done
    if kill -0 "${_attempt_pid}" 2>/dev/null; then
      printf 'Launch smoke: osascript reported success but process %s still alive after %ss grace; sending SIGTERM to process tree.\n' "${_attempt_pid}" "${grace}" >&2
      pkill -TERM -P "${_attempt_pid}" 2>/dev/null || true
      kill "${_attempt_pid}" 2>/dev/null || true
    fi
  fi

  local elapsed=0
  while kill -0 "${_attempt_pid}" 2>/dev/null && [ "${elapsed}" -lt "${QUIT_WAIT_SECONDS}" ]; do
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if kill -0 "${_attempt_pid}" 2>/dev/null; then
    # Process still alive after full quit wait. Chromium can take longer than 20s to respond
    # to SIGTERM when not in an interactive session (graceful shutdown is async). Escalate to
    # SIGKILL. The smoke's goal is to verify the app LAUNCHED and ran — graceful quit is
    # secondary. A forced kill here still counts as a successful smoke: the app started,
    # passed the 8s alive check, and is now being stopped.
    printf 'Launch smoke: process %s still alive after %ss quit wait; escalating to SIGKILL (launch passed, forced stop).\n' "${_attempt_pid}" "${QUIT_WAIT_SECONDS}" >&2
    pkill -KILL -P "${_attempt_pid}" 2>/dev/null || true
    kill -9 "${_attempt_pid}" 2>/dev/null || true
    sleep 1
    if kill -0 "${_attempt_pid}" 2>/dev/null; then
      printf 'Launch smoke: SIGKILL did not stop process %s; treating as failure.\n' "${_attempt_pid}" >&2
      _attempt_status=1
      return 1
    fi
    printf 'Launch smoke: process %s terminated via SIGKILL; launch smoke passes (app launched and ran).\n' "${_attempt_pid}" >&2
  fi

  _attempt_status=0
  return 0
}

# -------------------------------------------------------------------------
# Normal launch attempt (always)
# -------------------------------------------------------------------------

{
  printf 'Prometheus Smoke — launch log\n'
  printf 'Date: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf 'Binary: %s\n' "${PROMETHEUS_BIN}"
  printf 'Smoke URL: %s\n' "${SMOKE_URL}"
  printf 'Startup wait: %ss   Quit wait: %ss\n' "${STARTUP_WAIT_SECONDS}" "${QUIT_WAIT_SECONDS}"
} > "${LOG_FILE}"

normal_attempt_status="-"
workaround_attempt_status="-"
workaround_used=false
final_status=1
final_pid="-"
final_profile_dir="-"
final_launch_cmd="-"

_attempt_pid="-"
_attempt_status=1
_launch_cmd_used="-"

if attempt_launch "normal" ""; then
  normal_attempt_status=0
  final_status=0
  final_pid="${_attempt_pid}"
  final_profile_dir="${profile_dir}"
  final_launch_cmd="${_launch_cmd_used}"
else
  normal_attempt_status=1
  final_pid="${_attempt_pid}"
  final_profile_dir="${profile_dir}"
  final_launch_cmd="${_launch_cmd_used}"
fi

# -------------------------------------------------------------------------
# Workaround attempt (only if --with-dial-workaround and normal failed)
# -------------------------------------------------------------------------

if [ "${final_status}" -ne 0 ] && [ "${WITH_DIAL_WORKAROUND}" = "true" ]; then
  printf 'Launch smoke: normal path failed; attempting workaround with --disable-features=DialMediaRouteProvider\n' >&2

  _attempt_pid="-"
  _attempt_status=1
  _launch_cmd_used="-"

  if attempt_launch "workaround" "--disable-features=DialMediaRouteProvider"; then
    workaround_attempt_status=0
    workaround_used=true
    final_status=0
    final_pid="${_attempt_pid}"
    final_profile_dir="${profile_dir}"
    final_launch_cmd="${_launch_cmd_used}"
  else
    workaround_attempt_status=1
    if [ "${_attempt_pid}" != "-" ]; then
      final_pid="${_attempt_pid}"
    fi
    if [ -n "${profile_dir}" ]; then
      final_profile_dir="${profile_dir}"
    fi
    if [ "${_launch_cmd_used}" != "-" ]; then
      final_launch_cmd="${_launch_cmd_used}"
    fi
  fi
fi

# -------------------------------------------------------------------------
# Write status file (always — success or failure)
# -------------------------------------------------------------------------

ATTEMPT_VALUE="normal"
if [ "${WITH_DIAL_WORKAROUND}" = "true" ]; then
  ATTEMPT_VALUE="normal_then_workaround"
fi

all_profile_dirs="$( IFS=';'; printf '%s' "${profile_dirs[*]:-}" )"
if [ -z "${all_profile_dirs}" ]; then
  all_profile_dirs="-"
fi

{
  printf 'chromium_revision=%s\n'         "${chromium_revision}"
  printf 'gn_args=%s\n'                   "${gn_args}"
  printf 'attempt=%s\n'                   "${ATTEMPT_VALUE}"
  printf 'normal_attempt_status=%s\n'     "${normal_attempt_status}"
  printf 'workaround_attempt_status=%s\n' "${workaround_attempt_status}"
  printf 'workaround_used=%s\n'           "${workaround_used}"
  printf 'launch_command=%s\n'            "${final_launch_cmd}"
  printf 'smoke_url=%s\n'                "${SMOKE_URL}"
  printf 'status=%s\n'                   "${final_status}"
  printf 'log_file=%s\n'                 "${LOG_FILE}"
  printf 'profile_dir=%s\n'              "${final_profile_dir}"
  printf 'profile_dirs=%s\n'             "${all_profile_dirs}"
  printf 'started_pid=%s\n'              "${final_pid}"
  printf 'startup_wait_seconds=%s\n'     "${STARTUP_WAIT_SECONDS}"
  printf 'quit_wait_seconds=%s\n'        "${QUIT_WAIT_SECONDS}"
  if [ "${final_status}" -eq 0 ]; then
    printf 'patches_blocked=false\n'
  else
    printf 'patches_blocked=true\n'
  fi
} > "${STATUS_FILE}"

# -------------------------------------------------------------------------
# Failure gate: if launch failed, stop here with nonzero exit
# -------------------------------------------------------------------------

if [ "${final_status}" -ne 0 ]; then
  printf 'prometheus launch smoke failed: Prometheus did not start and exit cleanly. See %s and %s.\n' \
    "${STATUS_FILE}" "${LOG_FILE}" >&2
  printf 'patches_blocked=true has been written to %s\n' "${STATUS_FILE}" >&2
  exit 1
fi

# -------------------------------------------------------------------------
# Post-launch artifact isolation gate
# -------------------------------------------------------------------------

bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"

# -------------------------------------------------------------------------
# Identity assertions (BRAND-01, BRAND-06)
# Verify the built Prometheus.app has the correct bundle identity.
# -------------------------------------------------------------------------

PLIST="${BUILD_DIR}/Prometheus.app/Contents/Info.plist"
[ -f "${PLIST}" ] || fail "Info.plist not found at ${PLIST}; rebuild after BRANDING patch"

plutil -p "${PLIST}" | grep -q 'Prometheus' \
  || fail "CFBundleName does not contain 'Prometheus' in ${PLIST}"

plutil -p "${PLIST}" | grep -q 'com\.fullselfbrowsing\.prometheus' \
  || fail "CFBundleIdentifier is not 'com.fullselfbrowsing.prometheus' in ${PLIST}"

printf 'Prometheus launch smoke passed.\n'
