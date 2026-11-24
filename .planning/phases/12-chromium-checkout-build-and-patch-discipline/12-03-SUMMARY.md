---
phase: "12-chromium-checkout-build-and-patch-discipline"
plan: "03"
subsystem: "chromium-baseline-gates"
tags: ["chromium", "launch-smoke", "unmodified-baseline", "artifact-isolation", "shell-scripts", "evidence-files"]
dependency_graph:
  requires:
    - ".planning/chromium/check-chromium-env.sh: Plan 01 environment gate (invoked as preflight)"
    - ".planning/chromium/verify-artifact-isolation.sh: Plan 01 isolation gate (invoked post-launch)"
    - ".context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium: built Chromium binary from Plan 02"
  provides:
    - ".planning/chromium/smoke-launch-unmodified.sh: isolated-profile launch smoke for unmodified Chromium"
    - ".context/chromium-launch.status: launch evidence with revision, args, attempt status, workaround_used, patches_blocked"
    - ".context/chromium-launch.log: Chromium stdout/stderr from the launch attempt"
  affects:
    - "Phase 13+: patches_blocked=false in status file proves unmodified baseline and unblocks Prometheus Chromium patch work"
tech_stack:
  added:
    - "Bash launch smoke gate under .planning/chromium/"
    - "Launch evidence files under ignored .context/"
  patterns:
    - "Preflight env gate before launch (check-chromium-env.sh invocation)"
    - "mktemp isolated profile under .context to avoid polluting user data"
    - "8s startup check via kill -0; osascript bundle-ID-first quit with SIGTERM fallback; 20s bounded quit wait"
    - "Status file with all required keys (chromium_revision, depot_tools_revision, gn_args, attempt, normal_attempt_status, workaround_attempt_status, workaround_used, launch_command, smoke_url, status, log_file, profile_dir, started_pid, startup_wait_seconds, quit_wait_seconds, patches_blocked)"
    - "Post-launch artifact isolation gate (verify-artifact-isolation.sh invocation)"
key_files:
  created:
    - ".planning/chromium/smoke-launch-unmodified.sh"
  modified: []
decisions:
  - "osascript tries bundle ID 'org.chromium.Chromium' first, then app name 'Chromium'; if both fail, falls back to SIGTERM; all three paths are bounded by the 20s quit-wait loop"
  - "Normal attempt path is always run first; --with-dial-workaround retries only if normal fails, never by default"
  - "Profile dir created per attempt_launch() call with mktemp under .context; new profile ensures isolation from user data and across retry attempts"
  - "Status file is written exactly once after all attempts complete, covering both success and failure branches"
  - "patches_blocked=false only when status=0; otherwise patches_blocked=true; this is the gate that Phase 13 depends on"
  - "Script run confirmed: exit 0, status=0, workaround_used=false, patches_blocked=false on first normal attempt"
metrics:
  duration: "7 minutes"
  completed_date: "2026-06-24"
  tasks: 1
  files_created: 1
  files_modified: 0
---

# Phase 12 Plan 03: Unmodified Chromium Launch Smoke Gate Summary

**One-liner:** Executable launch gate starts unmodified Chromium with isolated profile and data-URL smoke page, proves 8s alive + osascript quit + clean exit, and writes chromium-launch.status with status=0, workaround_used=false, patches_blocked=false.

## What Was Built

### Task 1: smoke-launch-unmodified.sh

`.planning/chromium/smoke-launch-unmodified.sh` is an executable Bash script that:

- Accepts no argument (normal path only) or `--with-dial-workaround` (normal first; workaround retry on failure); rejects unknown arguments with prefix `chromium launch smoke failed:`
- Resolves `PROJECT_ROOT`, `DEPOT_TOOLS`, `CHROMIUM_SRC`, `BUILD_DIR`, `CHROMIUM_BIN`, `STATUS_FILE` (`.context/chromium-launch.status`), and `LOG_FILE` (`.context/chromium-launch.log`) from `SCRIPT_DIR`
- Sets `PATH="${DEPOT_TOOLS}:${PATH}"` and `DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"`
- Invokes `bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"` as preflight before any launch
- Records `chromium_revision` and `depot_tools_revision` from git and `gn_args` from `args.gn` for evidence
- Initializes `.context/chromium-launch.log` with header (Prometheus Chromium Baseline Smoke, date, binary, smoke URL, waits)
- Calls `attempt_launch "normal" ""` with smoke URL `data:text/html,<title>Prometheus Chromium Baseline Smoke</title><h1>OK</h1>` and flags `--user-data-dir`, `--no-first-run`, `--no-default-browser-check`
- Inside `attempt_launch()`: creates a fresh `mktemp -d .context/chromium-smoke-profile.XXXXXX` profile per attempt; sleeps 8s; requires `kill -0 "${pid}"` to succeed; requests quit via `osascript -e 'tell application id "org.chromium.Chromium" to quit'` then `osascript -e 'tell application "Chromium" to quit'`; falls back to SIGTERM; polls up to 20s with `kill -0`; terminates and returns failure if still alive
- If `--with-dial-workaround` and normal attempt failed: retries with `--disable-features=DialMediaRouteProvider`, sets `workaround_used=true`
- Writes `.context/chromium-launch.status` with all 16 required keys including `patches_blocked`
- Fails with nonzero exit and `patches_blocked=true` if launch did not exit cleanly
- Runs `bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"` on success
- Prints `Unmodified Chromium launch smoke passed.` on success

### Evidence Written

The script ran successfully on the first attempt against the built Chromium:

```
chromium_revision=0e8499df5172f55d0d29e2b92ef7e6a704529578
depot_tools_revision=a8c9ac983296908f8d662cb23ad6b8a0cae890b2
gn_args=is_debug = false is_component_build = true symbol_level = 0
attempt=normal
normal_attempt_status=0
workaround_attempt_status=-
workaround_used=false
status=0
patches_blocked=false
startup_wait_seconds=8
quit_wait_seconds=20
```

Launch succeeded: process alive after 8s, `osascript -e 'tell application id "org.chromium.Chromium" to quit'` worked on first try, process exited within 1s of quit request. Artifact isolation gate confirmed clean.

## Verification

All acceptance criteria passed:

- `rg 'Prometheus Chromium Baseline Smoke|chromium-launch.status|chromium-launch.log|chromium-smoke-profile'` found matches
- `rg 'normal_attempt_status|workaround_attempt_status|workaround_used|patches_blocked|--disable-features=DialMediaRouteProvider'` found matches
- `rg 'startup_wait_seconds|quit_wait_seconds|osascript|kill -0'` found matches
- `! rg '^[[:space:]]*(PATH=.*)?(fetch|gclient sync|gn gen|autoninja)'` confirmed no build commands
- `bash .planning/chromium/smoke-launch-unmodified.sh` exited 0; status file contains `status=0`, `workaround_used=false`, `patches_blocked=false`

## Deviations from Plan

None. Plan executed exactly as written.

## Known Stubs

None. The script launches the real locally-built Chromium binary and writes real evidence. No hardcoded empty values, placeholder text, or unwired data sources.

## Threat Surface Scan

The script introduces no new network endpoints, auth paths, or cross-service trust boundaries. It reads from `.context/chromium/src/out/Default` and writes only to `.context/` paths covered by root `.gitignore`. The isolated `mktemp` profile prevents user data contamination. The bounded quit wait (20s) with force-kill prevents indefinite hangs. The `patches_blocked` field in the status file is the single unambiguous gate that downstream phases must read before introducing Prometheus source modifications.

No new threat flags beyond those already covered in the plan's STRIDE threat register (T-12-13 through T-12-18).

## Requirements Addressed

- CHROM-06: Developer can run the unmodified Chromium app from the local build before Prometheus modifications begin — proven by `smoke-launch-unmodified.sh` exit 0 and `patches_blocked=false`
- CHROM-07: Reproducible build/run script with explicit paths, no shell profile assumptions, isolated profile state, predictable status/log files under ignored `.context/`

## Self-Check: PASSED

Files exist:
- `.planning/chromium/smoke-launch-unmodified.sh` - FOUND
- `.context/chromium-launch.status` - FOUND (under ignored .context/)
- `.context/chromium-launch.log` - FOUND (under ignored .context/)

Commits exist:
- d29783d05 (feat(12-03): add unmodified Chromium launch smoke gate) - FOUND
