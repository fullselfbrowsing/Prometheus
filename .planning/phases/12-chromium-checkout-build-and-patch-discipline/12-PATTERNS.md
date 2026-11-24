# Phase 12: Chromium Checkout, Build, and Patch Discipline - Pattern Map

**Mapped:** 2026-06-23
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/chromium/check-chromium-env.sh` | utility/test gate | batch, file-I/O | `.planning/preservation/verify-preservation.sh`; `.planning/chromium/CHROMIUM-CHECKOUT.md` | role-match |
| `.planning/chromium/verify-artifact-isolation.sh` | utility/test gate | batch, file-I/O | `.planning/preservation/verify-preservation.sh` | exact |
| `.planning/chromium/build-chromium-baseline.sh` | utility/build script | batch, file-I/O | `.planning/chromium/CHROMIUM-CHECKOUT.md`; `.planning/preservation/verify-preservation.sh` | role-match |
| `.planning/chromium/smoke-launch-unmodified.sh` | utility/smoke test | request-response, file-I/O | `.planning/chromium/CHROMIUM-CHECKOUT.md`; `.planning/preservation/verify-preservation.sh` | role-match |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | config/documentation | transform, file-I/O | `.planning/chromium/CHROMIUM-CHECKOUT.md` | exact |
| `.gitignore` (conditional tracked policy) | config | file-I/O | `/Users/lakshman/conductor/repos/prometheus/.git/info/exclude`; `.planning/preservation/verify-preservation.sh` | role-match |

## Pattern Assignments

### `.planning/chromium/check-chromium-env.sh` (utility/test gate, batch/file-I/O)

**Analog:** `.planning/preservation/verify-preservation.sh`

Use this as a small planning-owned Bash gate. Do not add product/runtime scripts at the repo root; Phase 12 context lines 24-28 says these scripts belong under `.planning/chromium/`, must use explicit paths, and must fail before long Chromium commands.

**Shell header and root resolution pattern** (`.planning/preservation/verify-preservation.sh` lines 1-6):
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$SOURCE_ROOT"
```

For `.planning/chromium/*.sh`, keep the same relative root calculation. Rename `SOURCE_ROOT` to `PROJECT_ROOT` only if that name is used consistently across the new Chromium scripts.

**Failure helper pattern** (`.planning/preservation/verify-preservation.sh` lines 14-17):
```bash
fail() {
  printf 'preservation check failed: %s\n' "$1" >&2
  exit 1
}
```

Copy the shape, but use a Chromium-specific prefix such as `chromium env check failed:`. Every missing prerequisite should include exact remediation, per context lines 26-28.

**Existing environment evidence to validate** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 70-104):
```text
/Applications/Xcode.app
Xcode 26.5
Build version 17F42

/Applications/Xcode.app/Contents/Developer

xcodebuild -version -> Xcode 26.5 / Build version 17F42
xcrun metal -v -> Apple metal version 32023.883
```

Check these with commands rather than hard-coding the version as the only acceptable value. The script should fail if full Xcode, active developer directory, or Metal are missing, and print the known remediation from `CHROMIUM-CHECKOUT.md` lines 92-97.

**Chromium path and GN args pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 106-114 and `.context/chromium/src/out/Default/args.gn` lines 1-3):
```bash
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
```

```gn
is_debug = false
is_component_build = true
symbol_level = 0
```

The env script should verify `.context/depot_tools`, `.context/chromium/src`, `out/Default/args.gn`, `buildtools/mac/gn`, and `out/Default/Chromium.app/Contents/MacOS/Chromium`. It should not run `fetch chromium`; context line 26 explicitly forbids automatic fetch during normal validation.

**Argument dispatch pattern** (`.planning/preservation/verify-preservation.sh` lines 186-207):
```bash
case "${1:-}" in
  --artifacts-only)
    check_preservation_artifacts
    ;;
  --dossier-only)
    check_dossier_evidence
    check_migration_map
    check_visual_ledger
    check_freeze_docs
    ;;
  "")
    check_preservation_artifacts
    check_dossier_evidence
    check_migration_map
    check_visual_ledger
    check_freeze_docs
    check_stale_docs
    ;;
  *)
    fail "unknown argument: $1"
    ;;
esac
```

Use this for any focused modes the planner adds, but keep the default path as the full env check required by validation lines 41 and 53.

---

### `.planning/chromium/verify-artifact-isolation.sh` (utility/test gate, batch/file-I/O)

**Analog:** `.planning/preservation/verify-preservation.sh`

This is the closest exact analog. It already checks ignored `.context` artifacts, root tracking state, and fails with a concrete message.

**Root git ignore/tracking pattern** (`.planning/preservation/verify-preservation.sh` lines 64-69):
```bash
git check-ignore -q "$bundle" || fail "preservation bundle is not ignored by root git: $bundle"
git check-ignore -q "$patch_dir" || fail "preservation patch directory is not ignored by root git: $patch_dir"

if git ls-files -- "$bundle" "$patch_dir" | rg -q .; then
  fail "preservation artifacts must not be tracked by root git"
fi
```

Adapt this to assert ignore/tracking coverage for `.context/`, `.gclient`, Chromium `out/`, depot_tools, logs, caches, and generated artifacts. Use `git check-ignore -q` for ignored paths and `git ls-files -- ... | rg -q .` for tracked-artifact failures.

**Stale scan/error-status pattern** (`.planning/preservation/verify-preservation.sh` lines 164-183):
```bash
local stale_pattern
stale_pattern='cmake -S falkon|falkon/tools|detached.*screen|prometheus-chromium-build.*running|built on Qt and QtWebEngine'

local stale_files=(README.md .planning/STATE.md .planning/chromium/CHROMIUM-CHECKOUT.md)
local file
for file in "${stale_files[@]}"; do
  [ -r "$file" ] || fail "missing or unreadable stale-doc scan target: $file"
done

set +e
rg -n "$stale_pattern" "${stale_files[@]}"
local rg_status=$?
set -e

if [ "$rg_status" -eq 0 ]; then
  fail "stale active Falkon/build docs remain"
fi

[ "$rg_status" -eq 1 ] || fail "stale-doc scan failed with rg exit status $rg_status"
```

Use the same `set +e` / status handling if the isolation script scans `git status --short` for forbidden paths. A zero match should fail; an `rg` status greater than 1 should fail as a command error.

**Current ignore-policy analog** (`/Users/lakshman/conductor/repos/prometheus/.git/info/exclude` lines 1-8):
```gitignore
# git ls-files --others --exclude-from=.git/info/exclude
# Lines that start with '#' are comments.
.context/
.conductor/settings.local.toml
.conductor/settings.local.json
```

The current real source of ignore coverage is `.context/` in the shared gitdir exclude. Validation lines 53-56 require either a tracked ignore policy or an explicit documented decision that this remains gitdir-exclude based; `verify-artifact-isolation.sh` must prove whichever path the planner chooses.

---

### `.planning/chromium/build-chromium-baseline.sh` (utility/build script, batch/file-I/O)

**Analogs:** `.planning/chromium/CHROMIUM-CHECKOUT.md` for Chromium commands and evidence; `.planning/preservation/verify-preservation.sh` for shell gate mechanics.

**GN generation command pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 106-120):
```bash
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
```

Keep the command rooted in `.context/chromium/src`, but resolve the absolute path from `SCRIPT_DIR` instead of baking the user workspace path into the script.

**Build command pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 126-135):
```bash
cd /Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src

AI_AGENT=1 \
PATH="/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/depot_tools:$PATH" \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
autoninja -C out/Default chrome
```

The build script should call `autoninja -C out/Default chrome`; do not substitute root Makefiles, raw compiler calls, or `fetch chromium`.

**Evidence/status pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 137-145):
```text
Log file: .context/chromium-build-screen.log
Exit status file: .context/chromium-build-screen.status
Exit status: 0
Working directory: .context/chromium/src
Expected Siso flags: --quiet --batch=false --heartbeat_period=30s --offline
```

Write bounded logs/status under `.context/` and record path/status in `CHROMIUM-CHECKOUT.md`. Context lines 19-22 say full transcripts are not required unless diagnosing failure.

**Build args rationale pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 170-184):
```gn
is_debug = false
is_component_build = true
symbol_level = 0
```

Preserve these unless validation proves a need to change them. If changed, the script and docs must record the rationale.

**Validation argument pattern** (`12-VALIDATION.md` lines 22-24 and 43):
```text
git diff --check && bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/build-chromium-baseline.sh --no-op-ok && bash .planning/chromium/smoke-launch-unmodified.sh && bash .planning/chromium/verify-artifact-isolation.sh
```

Support `--no-op-ok` for the plan gate. Use the `case "${1:-}"` shape from `verify-preservation.sh` lines 186-207 for focused mode parsing.

---

### `.planning/chromium/smoke-launch-unmodified.sh` (utility/smoke test, request-response/file-I/O)

**Analogs:** `.planning/chromium/CHROMIUM-CHECKOUT.md` for the actual launch command; `.planning/preservation/verify-preservation.sh` for fail-fast script structure.

There is no existing executable process-control launch script in the root codebase. Treat this as a role-match, not an exact copy. The script still must use the same shell header, root resolution, `fail()`, and bounded evidence patterns used by the preservation verifier and Chromium handoff.

**Locked launch-success contract** (`12-CONTEXT.md` lines 18-22):
```markdown
- **D-01:** A passing launch check requires the built Chromium app to start, open a local or `data:` smoke page, exit cleanly, and leave recorded evidence.
- **D-02:** The normal launch path should be attempted by default. Document `--disable-features=DialMediaRouteProvider` as a macOS development workaround for repeated local network permission prompt noise, but do not make it the default baseline proof unless needed.
- **D-03:** Phase 12 evidence should record the launch command, Chromium revision, GN args, status, and log/status file paths.
- **D-04:** If the clean Chromium build succeeds but unmodified launch verification fails, Prometheus-specific Chromium patches are blocked until the launch blocker is fixed or explicitly documented as a launch blocker.
```

**Launch command pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 147-168):
```bash
/Users/lakshman/conductor/workspaces/prometheus/puebla/.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium
```

```bash
out/Default/Chromium.app/Contents/MacOS/Chromium --disable-features=DialMediaRouteProvider
```

Attempt the normal launch path first. The `--disable-features=DialMediaRouteProvider` command is a documented workaround only after the normal path is attempted and the reason is recorded.

**Research supplement for missing launch analog** (`12-RESEARCH.md` lines 380-403):
```bash
profile_dir="$(mktemp -d "${PROJECT_ROOT}/.context/chromium-smoke-profile.XXXXXX")"
log_file="${PROJECT_ROOT}/.context/chromium-launch.log"
status_file="${PROJECT_ROOT}/.context/chromium-launch.status"

"${CHROMIUM_BIN}" \
  --user-data-dir="${profile_dir}" \
  --no-first-run \
  --no-default-browser-check \
  'data:text/html,<title>Prometheus Chromium Baseline Smoke</title><h1>OK</h1>' \
  >"${log_file}" 2>&1 &
pid="$!"

sleep 5
osascript -e 'tell application id "org.chromium.Chromium" to quit' || true
wait "${pid}"
printf 'status=%s\nlog=%s\nprofile=%s\n' "$?" "${log_file}" "${profile_dir}" > "${status_file}"
```

Use this only as a starting shape; research line 405 says the `osascript` shutdown path must be validated before it counts as clean-exit proof.

**Manual prompt validation pattern** (`12-VALIDATION.md` lines 60-65):
```markdown
Run `bash .planning/chromium/smoke-launch-unmodified.sh`; if it blocks on OS UI, record the prompt and rerun with the documented workaround only after the normal launch path is attempted.
```

Do not make a workaround-only pass look like a clean baseline pass.

---

### `.planning/chromium/CHROMIUM-CHECKOUT.md` (config/documentation, transform/file-I/O)

**Analog:** `.planning/chromium/CHROMIUM-CHECKOUT.md`

Update this file in place as the canonical Chromium baseline handoff. Do not split baseline revision, build evidence, launch evidence, and patch discipline into separate docs unless the planner adds a small linked evidence file under `.planning/chromium/`.

**Header/status/local path pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 1-17):
```markdown
# Chromium Checkout Handoff

**Created:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Chromium source checkout complete; Xcode/Metal toolchain fixed; GN generation complete; first `chrome` build finished successfully; unmodified launch verification remains Phase 12 scope.

## Local Paths

| Item | Path |
|------|------|
| depot_tools | `.context/depot_tools` |
| Chromium gclient root | `.context/chromium` |
| Chromium source | `.context/chromium/src` |
```

Preserve this compact table style for any new evidence paths such as launch log/status, smoke profile, and isolation verifier.

**Revision recording pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 36-58):
````markdown
Recorded depot_tools revision:

```text
c46c2e905
```

Recorded Chromium revision:

```text
0e8499df5172f55d0d29e2b92ef7e6a704529578
```
````

Phase 12 research says depot_tools has advanced to `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`; update the depot_tools revision while preserving the Chromium baseline revision unless the checkout changes intentionally.

**Build evidence pattern** (`.planning/chromium/CHROMIUM-CHECKOUT.md` lines 122-145):
````markdown
## First Build Result

The first `chrome` build for the clean Chromium checkout completed successfully.

Recorded build result:

```text
Log file: .context/chromium-build-screen.log
Exit status file: .context/chromium-build-screen.status
Exit status: 0
Working directory: .context/chromium/src
Expected Siso flags: --quiet --batch=false --heartbeat_period=30s --offline
```
````

Use the same concise evidence style for launch: command, Chromium revision, GN args, status, log path, status path, and whether the normal path or workaround path was used.

**Patch-discipline source rules** (`12-CONTEXT.md` lines 30-34):
```markdown
- Future Chromium source modifications happen inside `.context/chromium/src` and are managed by the Chromium checkout's git state.
- The root Prometheus planning repo stores docs, scripts, evidence, and exported patch guidance, not copied Chromium source files.
- Record the upstream Chromium baseline revision and define future patch branch/export expectations before branding work starts.
- If root git becomes dirty because of Chromium checkout/build artifacts, planning or execution must stop until the artifact is cleaned, ignored, or isolated.
```

Add a section that names the future branch pattern and patch export expectation. Research lines 245-259 recommend `git new-branch prometheus/phase-13-branding` as the future source-edit branch shape.

**Docs verification pattern** (`12-VALIDATION.md` lines 41-45):
```text
rg '0e8499df5172f55d0d29e2b92ef7e6a704529578|ea253a3e3ae7653cafd343be001dc5cbe69b3ad0|is_debug=false|is_component_build=true|symbol_level=0|launch|git new-branch|format-patch' .planning/chromium/CHROMIUM-CHECKOUT.md
```

Make sure the updated doc satisfies this exact static check.

---

### `.gitignore` (conditional tracked policy) (config, file-I/O)

**Analog:** `/Users/lakshman/conductor/repos/prometheus/.git/info/exclude`

This file is conditional. Validation lines 53-56 allow either a tracked ignore policy or a documented decision that root isolation remains gitdir-exclude based. If the planner chooses the documented-decision route, do not create `.gitignore`; instead, document the current gitdir-exclude dependency in `CHROMIUM-CHECKOUT.md` and enforce it in `verify-artifact-isolation.sh`.

**Existing ignore pattern** (`/Users/lakshman/conductor/repos/prometheus/.git/info/exclude` lines 1-8):
```gitignore
# git ls-files --others --exclude-from=.git/info/exclude
# Lines that start with '#' are comments.
.context/
.conductor/settings.local.toml
.conductor/settings.local.json
```

**Root artifact check to pair with any tracked policy** (`.planning/preservation/verify-preservation.sh` lines 64-69):
```bash
git check-ignore -q "$bundle" || fail "preservation bundle is not ignored by root git: $bundle"
git check-ignore -q "$patch_dir" || fail "preservation patch directory is not ignored by root git: $patch_dir"

if git ls-files -- "$bundle" "$patch_dir" | rg -q .; then
  fail "preservation artifacts must not be tracked by root git"
fi
```

If `.gitignore` is created, keep the policy root-scoped and focused on Chromium/depot_tools artifacts. The planner should still verify real behavior with `git check-ignore -v`, `git ls-files`, and `git status --short`.

## Shared Patterns

### Planning-Owned Script Location
**Source:** `12-CONTEXT.md` lines 24-28  
**Apply to:** all `.planning/chromium/*.sh`

Scripts belong under `.planning/chromium/`, must use explicit paths/env vars, must avoid shell-profile reliance, and must write predictable evidence files. Do not add root-level product scripts in Phase 12.

### Fail-Fast Shell Gate
**Source:** `.planning/preservation/verify-preservation.sh` lines 1-17  
**Apply to:** all `.planning/chromium/*.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$SOURCE_ROOT"

fail() {
  printf 'preservation check failed: %s\n' "$1" >&2
  exit 1
}
```

Copy the structure; customize the failure prefix per script.

### Root Artifact Isolation
**Source:** `.planning/preservation/verify-preservation.sh` lines 64-69; gitdir exclude lines 1-8  
**Apply to:** `verify-artifact-isolation.sh`, `.gitignore` decision, `CHROMIUM-CHECKOUT.md`
```bash
git check-ignore -q "$bundle" || fail "preservation bundle is not ignored by root git: $bundle"
git check-ignore -q "$patch_dir" || fail "preservation patch directory is not ignored by root git: $patch_dir"

if git ls-files -- "$bundle" "$patch_dir" | rg -q .; then
  fail "preservation artifacts must not be tracked by root git"
fi
```

Adapt target paths to `.context/`, `.gclient`, `out/`, depot_tools, logs, caches, and generated artifacts. If root git becomes dirty from Chromium artifacts, context line 34 says planning/execution must stop.

### Bounded Evidence
**Source:** `.planning/chromium/CHROMIUM-CHECKOUT.md` lines 137-145; `12-CONTEXT.md` lines 19-22  
**Apply to:** build script, launch script, handoff doc
```text
Log file: .context/chromium-build-screen.log
Exit status file: .context/chromium-build-screen.status
Exit status: 0
Working directory: .context/chromium/src
Expected Siso flags: --quiet --batch=false --heartbeat_period=30s --offline
```

Record status, command, revision, GN args, and log/status paths. Keep full transcripts out of the root repo unless needed for failure diagnosis.

### Chromium Commands
**Source:** `.planning/chromium/CHROMIUM-CHECKOUT.md` lines 106-168  
**Apply to:** `check-chromium-env.sh`, `build-chromium-baseline.sh`, `smoke-launch-unmodified.sh`
```bash
./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'
autoninja -C out/Default chrome
out/Default/Chromium.app/Contents/MacOS/Chromium
```

Always run these from `.context/chromium/src` with absolute depot_tools and `DEVELOPER_DIR` paths resolved by the script.

### Validation Commands
**Source:** `12-VALIDATION.md` lines 20-24 and 41-45  
**Apply to:** all Phase 12 plans
```bash
git diff --check
bash -n .planning/chromium/*.sh
bash .planning/chromium/check-chromium-env.sh
bash .planning/chromium/build-chromium-baseline.sh --no-op-ok
bash .planning/chromium/smoke-launch-unmodified.sh
bash .planning/chromium/verify-artifact-isolation.sh
```

The planner should attach the focused command to each plan and run the full suite before verification.

## No Analog Found

All planned/conditional files have at least a role-match analog. There is no exact existing process-control launch script, so `smoke-launch-unmodified.sh` must combine the shell-gate pattern from `verify-preservation.sh`, the launch command from `CHROMIUM-CHECKOUT.md`, and the launch-smoke shape from `12-RESEARCH.md` lines 380-403.

## Metadata

**Analog search scope:** `.planning/`, `README.md`, root gitdir exclude, `.context/chromium/src/out/Default/args.gn`  
**Files scanned:** 202 non-`.context`/non-`.git` workspace files, plus targeted `.context` build args and gitdir exclude  
**Project instructions:** No `CLAUDE.md`, `.claude/skills/`, or `.agents/skills/` found in the workspace  
**Pattern extraction date:** 2026-06-23
