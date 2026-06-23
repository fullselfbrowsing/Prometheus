#!/usr/bin/env bash
set -euo pipefail

# Chromium baseline build reproduction gate.
# Source: Phase 12 decisions and Chromium Mac build docs.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]
# [CITED: https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md]
#
# Usage:
#   bash build-chromium-baseline.sh            # run GN + autoninja
#   bash build-chromium-baseline.sh --no-op-ok # same; both run GN gen + build

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"

export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

CONTEXT_DIR="${PROJECT_ROOT}/.context"
STATUS_FILE="${CONTEXT_DIR}/chromium-build-baseline.status"
LOG_FILE="${CONTEXT_DIR}/chromium-build-baseline.log"
FULL_LOG_TMP="${CONTEXT_DIR}/chromium-build-baseline-full.tmp"

GN_CMD="./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'"
BUILD_CMD="AI_AGENT=1 autoninja -C out/Default chrome"

fail() {
  local msg="$1"
  printf 'chromium baseline build failed: %s\n' "${msg}" >&2
  exit 1
}

# --- Argument handling ---
# Accepts: no argument or --no-op-ok. Both run GN gen + autoninja.
# Unknown arguments fail.

case "${1:-}" in
  ""|"--no-op-ok")
    : # both modes run the same GN + build commands
    ;;
  *)
    fail "unknown argument '${1}'; supported: (none) or --no-op-ok"
    ;;
esac

# --- Preflight: run environment gate ---

bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"

# --- Ensure .context dir exists for status/log output ---

mkdir -p "${CONTEXT_DIR}"

# --- Record revisions before build ---

chromium_revision="$(git -C "${CHROMIUM_SRC}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read Chromium HEAD from ${CHROMIUM_SRC}"

depot_tools_revision="$(git -C "${DEPOT_TOOLS}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read depot_tools HEAD from ${DEPOT_TOOLS}"

gn_args="$(tr '\n' ' ' < "${BUILD_DIR}/args.gn" 2>/dev/null | sed 's/[[:space:]]*$//')"

# --- Run GN generation ---

start_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
gn_status=1

(
  cd "${CHROMIUM_SRC}"
  ./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
) && gn_status=0 || gn_status=$?

# --- Run autoninja build, capturing output to a temporary full log ---

build_status=1

(
  cd "${CHROMIUM_SRC}"
  AI_AGENT=1 autoninja -C out/Default chrome
) >"${FULL_LOG_TMP}" 2>&1 && build_status=0 || build_status=$?

end_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- Write bounded log evidence (first 80 + last 200 lines) ---

{
  printf '=== Chromium baseline build log ===\n'
  printf 'command_start: %s\n' "${start_ts}"
  printf 'gn_command: %s\n' "${GN_CMD}"
  printf 'build_command: %s\n' "${BUILD_CMD}"
  printf '\n--- first 80 lines of build output ---\n'
  head -n 80 "${FULL_LOG_TMP}" 2>/dev/null || true
  printf '\n--- last 200 lines of build output ---\n'
  tail -n 200 "${FULL_LOG_TMP}" 2>/dev/null || true
  printf '\ncommand_end: %s\n' "${end_ts}"
} > "${LOG_FILE}"

# Remove the temporary full log after bounded evidence is written
rm -f "${FULL_LOG_TMP}"

# --- Compute overall status ---

if [ "${gn_status}" -eq 0 ] && [ "${build_status}" -eq 0 ]; then
  overall_status=0
else
  overall_status=1
fi

# --- Write status file with all required keys ---

{
  printf 'chromium_revision=%s\n' "${chromium_revision}"
  printf 'depot_tools_revision=%s\n' "${depot_tools_revision}"
  printf 'gn_args=%s\n' "${gn_args}"
  printf 'gn_status=%s\n' "${gn_status}"
  printf 'build_status=%s\n' "${build_status}"
  printf 'status=%s\n' "${overall_status}"
  printf 'log_file=%s\n' "${LOG_FILE}"
  printf 'working_directory=%s\n' "${CHROMIUM_SRC}"
  printf 'gn_command=%s\n' "${GN_CMD}"
  printf 'build_command=%s\n' "${BUILD_CMD}"
} > "${STATUS_FILE}"

# --- Fail if GN or build exited nonzero ---

if [ "${overall_status}" -ne 0 ]; then
  fail "GN status=${gn_status} build status=${build_status}; see ${LOG_FILE} for details"
fi

# --- Post-build artifact isolation gate ---

bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"

printf 'Chromium baseline build passed.\n'
