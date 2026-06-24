#!/usr/bin/env bash
set -euo pipefail

# Prometheus Chromium Baseline Smoke — unmodified launch gate.
# Source: Phase 12 decisions and Chromium Mac launch docs.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]
# [CITED: https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md]
#
# Usage:
#   bash smoke-launch-unmodified.sh                 # normal launch path only
#   bash smoke-launch-unmodified.sh --with-dial-workaround  # normal first; retry with DialMediaRouteProvider workaround on failure
#
# Evidence written:
#   .context/chromium-launch.status   — key=value launch status record
#   .context/chromium-launch.log      — Chromium stdout/stderr from the normal (and workaround) attempt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"
CHROMIUM_BIN="${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium"
STATUS_FILE="${PROJECT_ROOT}/.context/chromium-launch.status"
LOG_FILE="${PROJECT_ROOT}/.context/chromium-launch.log"

SMOKE_URL='data:text/html,<title>Prometheus Chromium Baseline Smoke</title><h1>OK</h1>'
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
    printf 'chromium launch smoke failed: unknown argument "%s"; supported: (none) or --with-dial-workaround\n' "${1}" >&2
    exit 1
    ;;
esac

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

fail() {
  printf 'chromium launch smoke failed: %s\n' "$1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Preflight: run environment gate
# -------------------------------------------------------------------------

bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"

# -------------------------------------------------------------------------
# Resolve revisions and GN args for evidence
# -------------------------------------------------------------------------

mkdir -p "${PROJECT_ROOT}/.context"

chromium_revision="$(git -C "${CHROMIUM_SRC}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read Chromium HEAD from ${CHROMIUM_SRC}"

depot_tools_revision="$(git -C "${DEPOT_TOOLS}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read depot_tools HEAD from ${DEPOT_TOOLS}"

gn_args="$(tr '\n' ' ' < "${BUILD_DIR}/args.gn" 2>/dev/null | sed 's/[[:space:]]*$//')"

# -------------------------------------------------------------------------
# Launch helper: attempt one Chromium launch, wait, quit cleanly.
# Returns 0 on clean exit; 1 on startup failure or timeout.
# Sets global: _attempt_pid, _attempt_status
# -------------------------------------------------------------------------

# Profile dir is created once per script invocation; reused if workaround retry.
profile_dir=""

attempt_launch() {
  local attempt_label="$1"    # "normal" or "workaround"
  local extra_flags="${2:-}"   # e.g. "--disable-features=DialMediaRouteProvider"

  profile_dir="$(mktemp -d "${PROJECT_ROOT}/.context/chromium-smoke-profile.XXXXXX")"

  local launch_cmd
  if [ -z "${extra_flags}" ]; then
    launch_cmd="${CHROMIUM_BIN} --user-data-dir=${profile_dir} --no-first-run --no-default-browser-check ${SMOKE_URL}"
  else
    launch_cmd="${CHROMIUM_BIN} --user-data-dir=${profile_dir} --no-first-run --no-default-browser-check ${extra_flags} ${SMOKE_URL}"
  fi

  # Append attempt separator to log
  {
    printf '\n=== %s launch attempt (%s) ===\n' "${attempt_label}" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    printf 'command: %s\n' "${launch_cmd}"
  } >> "${LOG_FILE}"

  # Launch Chromium, redirecting its output to the log file (append)
  "${CHROMIUM_BIN}" \
    --user-data-dir="${profile_dir}" \
    --no-first-run \
    --no-default-browser-check \
    ${extra_flags:+${extra_flags}} \
    "${SMOKE_URL}" \
    >> "${LOG_FILE}" 2>&1 &

  _attempt_pid="$!"
  _launch_cmd_used="${launch_cmd}"

  # --- Startup check: wait STARTUP_WAIT_SECONDS and require process still alive ---
  sleep "${STARTUP_WAIT_SECONDS}"

  if ! kill -0 "${_attempt_pid}" 2>/dev/null; then
    printf 'Launch smoke: process %s exited before startup wait completed.\n' "${_attempt_pid}" >&2
    _attempt_status=1
    return 1
  fi

  printf 'Launch smoke: process %s alive after %ss startup wait.\n' "${_attempt_pid}" "${STARTUP_WAIT_SECONDS}"

  # --- Request clean quit via osascript: bundle ID first, then app name ---
  local quit_sent=false
  if osascript -e 'tell application id "org.chromium.Chromium" to quit' 2>/dev/null; then
    quit_sent=true
  elif osascript -e 'tell application "Chromium" to quit' 2>/dev/null; then
    quit_sent=true
  fi

  if [ "${quit_sent}" = "false" ]; then
    printf 'Launch smoke: osascript quit failed; falling back to SIGTERM for pid %s.\n' "${_attempt_pid}" >&2
    kill "${_attempt_pid}" 2>/dev/null || true
  fi

  # --- Wait up to QUIT_WAIT_SECONDS for clean exit ---
  local elapsed=0
  while kill -0 "${_attempt_pid}" 2>/dev/null && [ "${elapsed}" -lt "${QUIT_WAIT_SECONDS}" ]; do
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if kill -0 "${_attempt_pid}" 2>/dev/null; then
    # Still alive after quit wait — timeout
    printf 'Launch smoke: process %s still alive after %ss quit wait; terminating.\n' "${_attempt_pid}" "${QUIT_WAIT_SECONDS}" >&2
    kill "${_attempt_pid}" 2>/dev/null || true
    sleep 1
    kill -9 "${_attempt_pid}" 2>/dev/null || true
    _attempt_status=1
    return 1
  fi

  _attempt_status=0
  return 0
}

# -------------------------------------------------------------------------
# Normal launch attempt (always)
# -------------------------------------------------------------------------

# Initialize log file
{
  printf 'Prometheus Chromium Baseline Smoke — launch log\n'
  printf 'Date: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf 'Binary: %s\n' "${CHROMIUM_BIN}"
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

{
  printf 'chromium_revision=%s\n'         "${chromium_revision}"
  printf 'depot_tools_revision=%s\n'      "${depot_tools_revision}"
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
  printf 'chromium launch smoke failed: Chromium did not start and exit cleanly. See %s and %s.\n' \
    "${STATUS_FILE}" "${LOG_FILE}" >&2
  printf 'patches_blocked=true has been written to %s\n' "${STATUS_FILE}" >&2
  exit 1
fi

# -------------------------------------------------------------------------
# Post-launch artifact isolation gate
# -------------------------------------------------------------------------

bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"

printf 'Unmodified Chromium launch smoke passed.\n'
