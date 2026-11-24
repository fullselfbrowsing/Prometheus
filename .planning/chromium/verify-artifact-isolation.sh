#!/usr/bin/env bash
set -euo pipefail

# Source: Phase 12 patch-discipline decisions and root git artifact isolation.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

fail() {
  printf 'chromium artifact isolation check failed: %s\n' "$1" >&2
  exit 1
}

# --- Assert .gitignore exists and contains required policy lines ---

[ -f ".gitignore" ] || fail ".gitignore does not exist at root; create it with the Phase 12 Chromium artifact isolation policy"

grep -qF '/.context/' .gitignore || fail ".gitignore is missing required policy line: /.context/"
grep -qF '/.gclient' .gitignore || fail ".gitignore is missing required policy line: /.gclient"
grep -qF '/.gclient_entries' .gitignore || fail ".gitignore is missing required policy line: /.gclient_entries"
grep -qF '/depot_tools/' .gitignore || fail ".gitignore is missing required policy line: /depot_tools/"
grep -qF '/out/' .gitignore || fail ".gitignore is missing required policy line: /out/"
grep -qF '/*.log' .gitignore || fail ".gitignore is missing required policy line: /*.log"
grep -qF '/*.status' .gitignore || fail ".gitignore is missing required policy line: /*.status"
grep -qF '/*.tmp' .gitignore || fail ".gitignore is missing required policy line: /*.tmp"
grep -qF '/*.cache' .gitignore || fail ".gitignore is missing required policy line: /*.cache"

# --- git check-ignore -v checks: ignore source must be .gitignore ---
# Each path must be ignored and the source must include .gitignore.

check_ignored_by_gitignore() {
  local path="$1"
  local result
  result="$(git check-ignore -v "${path}" 2>/dev/null)" || fail "path is not ignored by root git: ${path} (run: git check-ignore -v '${path}' to diagnose)"
  echo "${result}" | grep -q '\.gitignore' || fail "path ${path} is not ignored via .gitignore (currently: ${result}); root .gitignore policy must cover Chromium artifacts for reproducible fresh-clone isolation"
}

check_ignored_by_gitignore ".context/chromium/src/out/Default"
check_ignored_by_gitignore ".context/depot_tools/gclient"
check_ignored_by_gitignore ".context/chromium-build-screen.log"
check_ignored_by_gitignore ".context/chromium-launch.log"
check_ignored_by_gitignore ".gclient"
check_ignored_by_gitignore ".gclient_entries"
check_ignored_by_gitignore "depot_tools/gclient"
check_ignored_by_gitignore "out/Default"
check_ignored_by_gitignore "chromium-build-baseline.status"
check_ignored_by_gitignore "chromium-launch.status"

# --- Tracked-artifact check ---
# git ls-files must return nothing for known artifact paths.

tracked_output="$(git ls-files -- .context .gclient .gclient_entries depot_tools out chromium-build-baseline.log chromium-build-baseline.status chromium-launch.log chromium-launch.status 2>/dev/null)"
if [ -n "${tracked_output}" ]; then
  fail "root git tracks Chromium/depot_tools artifacts; tracked files: ${tracked_output}"
fi

# --- Dirty-state scan ---
# git status --short --untracked-files=all must not show forbidden root artifact paths.
# .planning/config.json and plan files being dirty is acceptable.
#
# WR-06: anchor each token to a path-segment boundary so the scan flags ONLY
# real Chromium artifacts and never false-positives on legitimately tracked
# files that merely share a prefix. The leading (^|[[:space:]]) keeps the match
# at path-start (git --short prefixes the path with a space); the trailing
# boundaries are what was missing before:
#   .context        -> only as a full segment: ".context/" or bare ".context"
#                      (so ".contextual.md" / ".contextual-thing.txt" do NOT match)
#   .gclient        -> ".gclient" or ".gclient_entries" as a full segment
#                      (so ".gclientconfig.md" does NOT match)
#   depot_tools/, out/ -> already segment-anchored by the trailing slash
#   evidence basenames -> match the EXACT producers only:
#       chromium-build-baseline{.status,.log,-full.tmp}  via chromium-build-baseline[-.]
#       chromium-launch{.status,.log}                    via chromium-launch[.]
#       chromium-smoke-profile.XXXXXX                    via chromium-smoke-profile[.]
#     (so "chromium-build-notes.md" / "chromium-launchpad-readme.md" do NOT match)
forbidden_artifact_re='(^|[[:space:]])(\.context(/|$)|\.gclient(_entries)?(/|$)|depot_tools/|out/|chromium-build-baseline[-.]|chromium-launch[.]|chromium-smoke-profile[.])'

dirty_output="$(git status --short --untracked-files=all 2>/dev/null)"
if echo "${dirty_output}" | grep -qE "${forbidden_artifact_re}"; then
  forbidden_lines="$(echo "${dirty_output}" | grep -E "${forbidden_artifact_re}")"
  fail "root git is dirty with forbidden Chromium artifact paths: ${forbidden_lines}"
fi

printf 'Chromium artifact isolation passed.\n'
