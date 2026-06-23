---
phase: "12-chromium-checkout-build-and-patch-discipline"
plan: "02"
subsystem: "chromium-baseline-gates"
tags: ["chromium", "build-reproduction", "autoninja", "gn", "shell-scripts", "evidence-files"]
dependency_graph:
  requires:
    - ".planning/chromium/check-chromium-env.sh: Plan 01 environment gate (invoked as preflight)"
    - ".planning/chromium/verify-artifact-isolation.sh: Plan 01 isolation gate (invoked post-build)"
  provides:
    - ".planning/chromium/build-chromium-baseline.sh: GN and autoninja reproduction gate for the Chromium baseline"
    - ".context/chromium-build-baseline.status: build evidence with revision, args, GN/build status"
    - ".context/chromium-build-baseline.log: bounded build output (first 80 + last 200 lines)"
  affects:
    - "Phase 12 Plans 03-04: build gate must pass before launch smoke and patch-discipline docs run"
    - "Phase 13+: confirmed baseline revision and locked GN args are prerequisites for Prometheus patches"
tech_stack:
  added:
    - "Bash build reproduction gate under .planning/chromium/"
    - "Bounded evidence files under ignored .context/"
  patterns:
    - "Preflight env gate before long commands (check-chromium-env.sh invocation)"
    - "Capture build output to temp file then write bounded head/tail log"
    - "Status file with all required keys (chromium_revision, depot_tools_revision, gn_args, gn_status, build_status, status, log_file, working_directory, gn_command, build_command)"
    - "Post-build artifact isolation gate (verify-artifact-isolation.sh invocation)"
key_files:
  created:
    - ".planning/chromium/build-chromium-baseline.sh"
  modified: []
decisions:
  - "Both no-argument and --no-op-ok invocations run the same GN gen + autoninja commands; --no-op-ok is accepted but not treated differently from the default path"
  - "GN command runs in a subshell from CHROMIUM_SRC so the working directory is isolated from the script root"
  - "Build command captures stdout+stderr to a temp file, then writes bounded head/tail evidence to LOG_FILE, then removes the temp full log"
  - "Status file is written even when gn_status or build_status is nonzero, so failure evidence is always available"
  - "Script fails after writing status file if overall_status != 0, ensuring nonzero exits block downstream work"
metrics:
  duration: "1 minute"
  completed_date: "2026-06-23"
  tasks: 1
  files_created: 1
  files_modified: 0
---

# Phase 12 Plan 02: Chromium Baseline Build Reproduction Gate Summary

**One-liner:** Executable build gate runs locked GN args and AI_AGENT=1 autoninja --no-op-ok in 4s, writes chromium-build-baseline.status with status=0, and confirms artifact isolation post-build.

## What Was Built

### Task 1: build-chromium-baseline.sh

`.planning/chromium/build-chromium-baseline.sh` is an executable Bash script that:

- Accepts no argument or `--no-op-ok` (both run the same GN + build path); rejects unknown arguments with prefix `chromium baseline build failed:`
- Resolves `PROJECT_ROOT`, `DEPOT_TOOLS`, `CHROMIUM_SRC`, `BUILD_DIR`, and `DEVELOPER_DIR` from `SCRIPT_DIR` using the same canonical pattern as Plan 01
- Sets `PATH="${DEPOT_TOOLS}:${PATH}"` and `DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"`
- Invokes `bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"` as preflight
- Reads `chromium_revision` and `depot_tools_revision` from git before running commands
- Runs `./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'` from `${CHROMIUM_SRC}`
- Runs `AI_AGENT=1 autoninja -C out/Default chrome` capturing full output to a temporary file
- Writes `.context/chromium-build-baseline.log` with command timestamps, GN/build command strings, first 80 lines, and last 200 lines of output
- Removes the temporary full log after bounded evidence is written
- Writes `.context/chromium-build-baseline.status` with all ten required keys
- Fails with nonzero exit if either GN or build exit nonzero
- Runs `bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"` on success
- Prints `Chromium baseline build passed.` on success

### Evidence Written

The script ran successfully against the existing (already-built) checkout:

```
chromium_revision=0e8499df5172f55d0d29e2b92ef7e6a704529578
depot_tools_revision=ea253a3e3ae7653cafd343be001dc5cbe69b3ad0
gn_args=is_debug = false  is_component_build = true  symbol_level = 0
gn_status=0
build_status=0
status=0
log_file=.../.context/chromium-build-baseline.log
working_directory=.../.context/chromium/src
gn_command=./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
build_command=AI_AGENT=1 autoninja -C out/Default chrome
```

GN generation reported: `Done. Made 31437 targets from 4783 files in 4365ms`. Build was a no-op (`ninja: no work to do` equivalent) because the existing out/Default is already current with those args.

## Verification

All acceptance criteria passed:

- `rg` found both `gn gen out/Default --args=...` and `autoninja -C out/Default chrome` in the script
- `rg` found all required evidence field names in the script
- `rg` found both `check-chromium-env.sh` and `verify-artifact-isolation.sh` in the script
- No `fetch` or `gclient sync` lines found at the top of any line
- `bash .planning/chromium/build-chromium-baseline.sh --no-op-ok` exited 0 and wrote `status=0`

## Deviations from Plan

None. Plan executed exactly as written.

## Known Stubs

None. The script invokes real GN and autoninja commands against the live checkout and writes real status evidence. No hardcoded empty values, placeholder text, or unwired data sources.

## Threat Surface Scan

The script introduces no new network endpoints, auth paths, or trust-boundary changes. It reads from and writes to `.context/` paths that are ignored by root git. The bounded log truncation (first 80 + last 200 lines) prevents information disclosure of large build transcripts into root-tracked files. The artifact isolation gate runs post-build to assert `.context/` evidence stays ignored.

No new threat flags beyond those already covered in the plan's STRIDE threat register (T-12-07 through T-12-12).

## Requirements Addressed

- CHROM-02: GN args and `chrome` build target are now reproducible via `build-chromium-baseline.sh --no-op-ok`
- CHROM-03: Script documents locked GN args, explicit depot_tools and Xcode paths; preflight gate checks Xcode/Metal prerequisites
- CHROM-05: Status file records exact `chromium_revision=0e8499df5172f55d0d29e2b92ef7e6a704529578` on every run
- CHROM-07: Script uses absolute paths, accepts no interactive shell state, and writes predictable status/log files under ignored `.context/`

## Self-Check: PASSED

Files exist:
- `.planning/chromium/build-chromium-baseline.sh` - FOUND
- `.context/chromium-build-baseline.status` - FOUND (under ignored .context/)
- `.context/chromium-build-baseline.log` - FOUND (under ignored .context/)

Commits exist:
- af7dabc72 (feat(12-02): add Chromium baseline build reproduction script) - FOUND
