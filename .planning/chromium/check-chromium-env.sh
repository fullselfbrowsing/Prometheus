#!/usr/bin/env bash
set -euo pipefail

# Source: Phase 12 decisions and Chromium Mac build docs.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]
# [CITED: https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"
CHROMIUM_BIN="${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium"

export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

EXPECTED_CHROMIUM_REV="0e8499df5172f55d0d29e2b92ef7e6a704529578"

fail() {
  printf 'chromium env check failed: %s\n' "$1" >&2
  exit 1
}

# --- depot_tools checks ---

[ -d "${DEPOT_TOOLS}/.git" ] || fail "missing depot_tools .git at ${DEPOT_TOOLS}; clone with: git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ${DEPOT_TOOLS}"
[ -x "${DEPOT_TOOLS}/gclient" ] || fail "missing executable gclient at ${DEPOT_TOOLS}; clone depot_tools at ${DEPOT_TOOLS}"

# --- Chromium checkout checks ---

[ -f "${CHROMIUM_ROOT}/.gclient" ] || fail "missing .gclient at ${CHROMIUM_ROOT}; run: mkdir -p ${CHROMIUM_ROOT} && cd ${CHROMIUM_ROOT} && PATH=\"${DEPOT_TOOLS}:\$PATH\" fetch --no-history chromium"
[ -d "${CHROMIUM_SRC}/.git" ] || fail "missing Chromium source .git at ${CHROMIUM_SRC}; run: cd ${CHROMIUM_ROOT} && PATH=\"${DEPOT_TOOLS}:\$PATH\" fetch --no-history chromium"

# --- Baseline revision check ---

actual_rev="$(git -C "${CHROMIUM_SRC}" rev-parse HEAD 2>/dev/null)" || fail "could not read Chromium HEAD from ${CHROMIUM_SRC}"
[ "${actual_rev}" = "${EXPECTED_CHROMIUM_REV}" ] || fail "Chromium HEAD is ${actual_rev}, expected ${EXPECTED_CHROMIUM_REV}; do not run gclient sync or rebase until later phases document an intentional change"

# --- GN binary check ---

[ -x "${CHROMIUM_SRC}/buildtools/mac/gn" ] || fail "missing executable GN binary at ${CHROMIUM_SRC}/buildtools/mac/gn; ensure Chromium checkout hooks ran"

# --- Build directory and args.gn check ---

[ -r "${BUILD_DIR}/args.gn" ] || fail "missing readable ${BUILD_DIR}/args.gn; run GN generation from ${CHROMIUM_SRC}: PATH=\"${DEPOT_TOOLS}:\$PATH\" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'"

# --- GN arg checks (exact lines required) ---

grep -qF 'is_debug = false' "${BUILD_DIR}/args.gn" || fail "args.gn does not contain 'is_debug = false'; expected baseline GN args in ${BUILD_DIR}/args.gn"
grep -qF 'is_component_build = true' "${BUILD_DIR}/args.gn" || fail "args.gn does not contain 'is_component_build = true'; expected baseline GN args in ${BUILD_DIR}/args.gn"
grep -qF 'symbol_level = 0' "${BUILD_DIR}/args.gn" || fail "args.gn does not contain 'symbol_level = 0'; expected baseline GN args in ${BUILD_DIR}/args.gn"

# --- Built binary check ---

[ -x "${CHROMIUM_BIN}" ] || fail "missing executable Chromium binary at ${CHROMIUM_BIN}; rebuild with: cd ${CHROMIUM_SRC} && AI_AGENT=1 PATH=\"${DEPOT_TOOLS}:\$PATH\" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default chrome"

# --- Xcode developer directory check ---

actual_devdir="$(xcode-select -p 2>/dev/null)" || fail "xcode-select -p failed; install full Xcode from the Mac App Store and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
[ "${actual_devdir}" = "/Applications/Xcode.app/Contents/Developer" ] || fail "xcode-select -p returned '${actual_devdir}', expected '/Applications/Xcode.app/Contents/Developer'; run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"

# --- Xcode version check ---

xcodebuild -version >/dev/null 2>&1 || fail "xcodebuild -version failed; accept the Xcode license with: sudo xcodebuild -license accept && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -runFirstLaunch"

# --- Metal toolchain check ---

xcrun metal -v >/dev/null 2>&1 || fail "Metal toolchain unavailable; run: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain"

# --- autoninja check (through resolved depot_tools PATH) ---
# Probes: autoninja --version must succeed via absolute depot_tools PATH.
(PATH="${DEPOT_TOOLS}:${PATH}" command -v autoninja && PATH="${DEPOT_TOOLS}:${PATH}" autoninja --version) >/dev/null 2>&1 \
  || fail "autoninja not found or not working in PATH; ensure depot_tools at ${DEPOT_TOOLS} is present and on PATH"

# --- Binary architecture check ---

bin_file_output="$(file "${CHROMIUM_BIN}")" || fail "file command failed on ${CHROMIUM_BIN}"
echo "${bin_file_output}" | grep -q 'Mach-O' || fail "Chromium binary at ${CHROMIUM_BIN} is not a Mach-O executable; got: ${bin_file_output}"
echo "${bin_file_output}" | grep -q 'arm64' || fail "Chromium binary at ${CHROMIUM_BIN} is not arm64; got: ${bin_file_output}"

# --- gclient validate (after path checks pass) ---

(cd "${CHROMIUM_ROOT}" && gclient validate >/dev/null 2>&1) || fail "gclient validate failed in ${CHROMIUM_ROOT}; checkout may be incomplete or .gclient file is malformed"

printf 'Chromium environment check passed.\n'
