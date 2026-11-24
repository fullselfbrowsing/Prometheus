---
phase: 12-chromium-checkout-build-and-patch-discipline
reviewed: 2026-06-23T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .planning/chromium/check-chromium-env.sh
  - .planning/chromium/build-chromium-baseline.sh
  - .planning/chromium/smoke-launch-unmodified.sh
  - .planning/chromium/verify-artifact-isolation.sh
  - .gitignore
findings:
  critical: 0
  warning: 6
  info: 5
  total: 11
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-06-23
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed four Bash gate scripts (`set -euo pipefail`) that drive a local Chromium baseline checkout/build/launch and enforce git artifact isolation, plus the root `.gitignore` policy. The scripts are well structured: all four `cd` to a resolved `PROJECT_ROOT` (CWD-independent), all four pass `bash -n`, path variables are consistent across scripts, the real Chromium launch invocation quotes its arguments correctly (space-safe), the `set -e` / `&&...||` status-capture patterns are correct, and the `.gitignore` policy genuinely covers every artifact path the scripts write while keeping the deliverable scripts and docs tracked (verified live with `git check-ignore -v` and `git ls-files`).

No Critical issues found. No injection, no hardcoded secrets, no command-injection via the supported flags (unknown args are rejected; `--user-data-dir` and `SMOKE_URL` are passed as properly quoted argv, not via a shell string).

However, the launch lifecycle in `smoke-launch-unmodified.sh` has a confirmed, observable resource-leak defect: temp profile directories under `.context/chromium-smoke-profile.*` are never removed — three already exist on disk from prior runs (~18MB total) and grow unbounded every run. Compounding this, there is no `trap` handler, so any interrupt or early exit during the 8s startup wait or 20s quit poll orphans the backgrounded Chromium process and leaves its profile dir behind; the force-kill fallback only targets `$!` and does not reap Chromium's Helper child processes. The build script also silently drops GN's stdout/stderr from its evidence log (only `autoninja` output is captured), so a GN-generation failure produces a status-file `gn_status` but no diagnostic log lines. These are the principal findings below.

The known/accepted items from the prompt (scripts intentionally do not run `fetch`/`gclient sync`; build is current; `kill -0` alive-check is an accepted proxy for "rendered") are confirmed and are NOT raised as new defects.

## Warnings

### WR-01: Temp profile directories are never cleaned up — confirmed unbounded leak

**File:** `.planning/chromium/smoke-launch-unmodified.sh:98` (creation; no corresponding removal anywhere in file)
**Issue:** `attempt_launch` creates a fresh isolated profile with `mktemp -d "${PROJECT_ROOT}/.context/chromium-smoke-profile.XXXXXX"` on every call and never removes it. There is no `rm -rf` of the profile dir and no `trap` to clean it on exit. This is not theoretical — the live workspace already contains three leftovers from prior runs:
```
8.8M  .context/chromium-smoke-profile.36lPZp
8.8M  .context/chromium-smoke-profile.RS66c0
  0B  .context/chromium-smoke-profile.VpjNUV
```
Each successful run leaves ~9MB; each run that triggers the `--with-dial-workaround` retry leaks a *second* dir (the failed normal attempt's profile, see WR-02). They are correctly git-ignored (caught by `/.context/`), so this is disk-hygiene rather than a tracking violation — but it grows without bound and clutters the very `.context` directory the phase is trying to keep clean.
**Fix:** Track every created profile dir and remove them via an EXIT trap so cleanup happens on success, failure, and interrupt alike:
```bash
profile_dirs=()
cleanup() {
  # kill any still-running launched process, then remove all profile dirs
  [ "${_attempt_pid:-}" != "-" ] && kill "${_attempt_pid}" 2>/dev/null || true
  for d in "${profile_dirs[@]:-}"; do
    [ -n "${d}" ] && rm -rf "${d}" 2>/dev/null || true
  done
}
trap cleanup EXIT
# in attempt_launch, after mktemp:
profile_dir="$(mktemp -d "${PROJECT_ROOT}/.context/chromium-smoke-profile.XXXXXX")"
profile_dirs+=("${profile_dir}")
```
(If the recorded `profile_dir` must survive for post-run inspection, keep only the final successful one and still remove the rest.)

### WR-02: No trap handler — interrupt or early exit during sleep orphans the Chromium process and its profile

**File:** `.planning/chromium/smoke-launch-unmodified.sh:114-167` (background launch + `sleep ${STARTUP_WAIT_SECONDS}` line 126 + `sleep 1` quit poll line 152)
**Issue:** Chromium is launched in the background (`... & ; _attempt_pid="$!"`). Between that launch and the kill/quit logic the script blocks in `sleep 8` and then in a `sleep 1` poll loop for up to 20s. With `set -e` and **no `trap`**, an operator `Ctrl-C` (or a SIGTERM, or any uncaught failure introduced later) during either sleep terminates the script immediately, leaving the backgrounded Chromium process (`$_attempt_pid`) running and its `mktemp` profile dir on disk. There is no cleanup-on-signal path. This directly undermines the "no orphaned process / no leftover temp-profile" lifecycle guarantee the smoke gate is supposed to provide.
**Fix:** Install the EXIT trap from WR-01 (EXIT fires on normal exit, on `exit 1`, and on the default signal-triggered exit when combined with `trap cleanup INT TERM EXIT`). Trapping INT/TERM explicitly ensures the child is killed and the profile removed before the script dies:
```bash
trap cleanup INT TERM EXIT
```

### WR-03: Force-kill targets only `$!` and orphans Chromium Helper child processes

**File:** `.planning/chromium/smoke-launch-unmodified.sh:146,159,161`
**Issue:** The SIGTERM fallback (`kill "${_attempt_pid}"`) and the timeout force-kill (`kill -9 "${_attempt_pid}"`) act only on the single PID captured from `$!` — the main browser process. Chromium spawns multiple Helper processes (Renderer, GPU, Network service) as children. On macOS, killing the parent does not reap its children; they are reparented to `launchd` and can linger holding the profile/socket. Because the launcher does not start Chromium in its own process group (no `setsid` / `set -m`) and does not use a process-group kill (`kill -- -PGID`) or `pkill -P`, the "terminate on timeout" path can leave Helper processes alive even though the script believes it cleaned up. In the happy path (osascript quit succeeds) Chromium tears down its own children, so this only bites the SIGTERM/SIGKILL fallback — but that fallback exists precisely for the failure case, where leaked helpers are most likely.
**Fix:** Launch in a new session and kill the whole group, or sweep children explicitly. Minimal child sweep:
```bash
# force-kill path:
pkill -TERM -P "${_attempt_pid}" 2>/dev/null || true
kill "${_attempt_pid}" 2>/dev/null || true
sleep 1
pkill -KILL -P "${_attempt_pid}" 2>/dev/null || true
kill -9 "${_attempt_pid}" 2>/dev/null || true
```
Or start with `setsid` (if available) / bash job control and `kill -- -"${_attempt_pid}"` for a true process-group kill.

### WR-04: Workaround retry leaks the failed normal attempt's profile and misreports it

**File:** `.planning/chromium/smoke-launch-unmodified.sh:98,199-205,219-237`
**Issue:** `profile_dir` is a single global that `attempt_launch` overwrites with a brand-new `mktemp` dir on each call (line 98). When the normal attempt fails and `--with-dial-workaround` triggers a second `attempt_launch`, the global is replaced. The normal attempt's profile directory is therefore (a) never removed and (b) no longer referenced — the status file's `profile_dir=` records only the final (workaround) dir. So in the retry path two profile dirs leak per run and the evidence under-reports them. This compounds WR-01.
**Fix:** Adopt the `profile_dirs=()` array + EXIT-trap cleanup from WR-01 so both attempts' dirs are tracked and removed. If evidence should list all profiles used, record the array (e.g. `profile_dirs=a;b`) rather than a single value.

### WR-05: GN-generation output is not captured to the evidence log

**File:** `.planning/chromium/build-chromium-baseline.sh:75-78` (GN subshell, no redirect) vs `84-87` (autoninja redirected to `FULL_LOG_TMP`)
**Issue:** The autoninja build subshell is redirected into `FULL_LOG_TMP` and then summarized (first 80 / last 200 lines) into `chromium-build-baseline.log`. The GN-generation subshell on lines 75-78 has **no redirection**, so its stdout/stderr go to the terminal and are never written to the temp log. The bounded evidence log therefore contains only ninja output. If GN generation fails (`gn_status != 0`), the status file records `gn_status=<n>` and the script calls `fail "GN status=..."`, but `chromium-build-baseline.log` contains zero GN diagnostics — the operator cannot see *why* GN failed from the recorded evidence, defeating the purpose of bounded log capture for the GN half of the build. Per D-03 evidence should be enough to diagnose failure.
**Fix:** Redirect the GN subshell into the same temp log (append) before the build appends to it, or capture GN to its own temp and include it in the summary:
```bash
(
  cd "${CHROMIUM_SRC}"
  ./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
) >"${FULL_LOG_TMP}" 2>&1 && gn_status=0 || gn_status=$?
# then append autoninja:
(
  cd "${CHROMIUM_SRC}"
  AI_AGENT=1 autoninja -C out/Default chrome
) >>"${FULL_LOG_TMP}" 2>&1 && build_status=0 || build_status=$?
```

### WR-06: Dirty-state and isolation regex uses over-broad, unanchored substrings

**File:** `.planning/chromium/verify-artifact-isolation.sh:64-65`
**Issue:** The forbidden-path scan uses `grep -qE '(^|\s)(\.context|\.gclient|\.gclient_entries|depot_tools/|out/|chromium-build|chromium-launch)'`. Several alternatives have no trailing boundary, so they match unrelated paths that merely *start* with the token. Confirmed by test:
```
?? chromium-build-notes-FOR-HUMANS.md   -> MATCH (false positive)
?? chromium-launchpad-readme.md          -> MATCH (false positive)
?? .contextual-thing.txt                 -> MATCH (false positive, ".context" prefix)
```
A legitimately tracked-intent root file named e.g. `chromium-build-notes.md` or `.contextual.md` would trip the isolation gate and block the pipeline with a misleading "forbidden Chromium artifact paths" error. The `(^|\s)` prefix does correctly anchor to path-start (git `--short` always prefixes the path with a space), so mid-path segments like `src/depot_tools/x` are *not* matched — that part is fine. The defect is purely the missing trailing boundary on `\.context`, `chromium-build`, and `chromium-launch`.
**Fix:** Anchor the tokens to a path-segment boundary (`/`, `.`, end-of-line, or whitespace). For example require a following `/`, `.`, `-`, or end for the artifact-name tokens, and match `.context` only as a full segment:
```bash
re='(^|\s)(\.context(/|$)|\.gclient(_entries)?(/|$)|depot_tools/|out/|chromium-(build|launch)[-.][[:alnum:]])'
```
Adjust to the exact artifact names actually written (`chromium-build-baseline.*`, `chromium-launch.*`, `chromium-smoke-profile.*`) so only those are forbidden.

## Info

### IN-01: Human-readable `launch_cmd` log string is built with unquoted expansions

**File:** `.planning/chromium/smoke-launch-unmodified.sh:102,104,110`
**Issue:** The `launch_cmd` string logged for evidence interpolates `${profile_dir}` and `${SMOKE_URL}` unquoted. If `PROJECT_ROOT` (hence `profile_dir`) ever contained a space, the *logged* command would be ambiguous/un-copy-pasteable. This is cosmetic only: the actual launch on lines 114-120 passes `--user-data-dir="${profile_dir}"` and `"${SMOKE_URL}"` as properly quoted argv, so execution is space-safe (verified). Only the evidence string is affected.
**Fix:** Quote the values in the display string, e.g. `--user-data-dir="${profile_dir}"` and wrap `${SMOKE_URL}` in single quotes, or build the string with `printf %q`.

### IN-02: Status files are written via direct truncation, not atomically

**File:** `.planning/chromium/build-chromium-baseline.sh:118-129`; `.planning/chromium/smoke-launch-unmodified.sh:249-270`
**Issue:** Both status files are written with `{ ...printf... } > "${STATUS_FILE}"`, which truncates in place. A crash or interrupt mid-block leaves a partially written status file that a downstream consumer could misread. Risk is low (the block is a handful of fast `printf`s with no slow commands inside), but it is not atomic.
**Fix:** Write to a temp file in the same directory and `mv` into place: `{ ... } > "${STATUS_FILE}.tmp" && mv -f "${STATUS_FILE}.tmp" "${STATUS_FILE}"`. (The `.tmp` is already ignored by `/.context/` and `/*.tmp`.)

### IN-03: `.gitignore` anchored globs `/*.log /*.status /*.tmp /*.cache` are redundant for `.context` artifacts

**File:** `.gitignore:7-10`
**Issue:** Every artifact the scripts write lives under `.context/`, which is fully ignored by `/.context/` (line 2). Verified: `git check-ignore -v` reports `.context/chromium-build-baseline.log`, `...-full.tmp`, `...launch.status`, etc. all resolve to `.gitignore:2:/.context/`, never to the `/*.log` family. The root-anchored `/*.log`, `/*.status`, `/*.tmp`, `/*.cache` and `/chromium-*.log`, `/chromium-*.status` lines only fire for files written directly at repo root — which these scripts never do. Not a bug (defense-in-depth against a future root-writing script, and `verify-artifact-isolation.sh:25-28` asserts these lines exist), just noting they are belt-and-suspenders for the current script set.
**Fix:** None required. Optionally add a comment noting these guard against future root-level artifact writes, since the current scripts only write under `.context/`.

### IN-04: `verify-artifact-isolation.sh` references `chromium-build-screen.log`, which no script writes

**File:** `.planning/chromium/verify-artifact-isolation.sh:42`
**Issue:** `check_ignored_by_gitignore ".context/chromium-build-screen.log"` asserts ignore-coverage for a filename that does not match any artifact the build script produces (it writes `chromium-build-baseline.log` and `...-full.tmp`). The check still passes because `/.context/` ignores everything under `.context/`, but the path is a stale/aspirational name that does not correspond to a real producer, which is mildly misleading for anyone auditing the gate's coverage map.
**Fix:** Replace with the actual produced filenames (`.context/chromium-build-baseline.log`, `.context/chromium-build-baseline-full.tmp`) so the coverage assertions map to real artifacts.

### IN-05: Smoke "alive after 8s" is an accepted proxy, but does not confirm the page rendered

**File:** `.planning/chromium/smoke-launch-unmodified.sh:126-134`
**Issue:** `kill -0 "${_attempt_pid}"` after the 8s wait only proves the browser PID still exists. A Chromium whose renderer crashed but whose browser process survived, or one that hung before painting, still passes the gate. This is explicitly acknowledged as an accepted machine-verifiable proxy in `12-VERIFICATION.md` (visual confirmation is the only human-required item), so it is recorded here for completeness, **not** as a new defect to fix in this phase.
**Fix:** None required for Phase 12. If stronger proof is wanted later, assert on a render signal — e.g. Chromium writing an expected `data:`-page artifact, a `--dump-dom`/headless screenshot, or a log line — rather than mere process liveness.

---

_Reviewed: 2026-06-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
