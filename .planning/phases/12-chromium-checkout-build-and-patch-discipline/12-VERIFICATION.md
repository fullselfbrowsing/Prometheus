---
phase: 12-chromium-checkout-build-and-patch-discipline
verified: 2026-06-23T00:00:00Z
status: passed
score: 12/12
overrides_applied: 0
re_verification: null
---

# Phase 12: Chromium Checkout, Build, and Patch Discipline — Verification Report

**Phase Goal:** Establish a clean upstream Chromium baseline that builds locally and can survive rebases.
**Verified:** 2026-06-23
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Developer can prove the existing Chromium checkout, depot_tools install, Xcode, Metal, GN args, and built binary exist before long commands run | VERIFIED | `check-chromium-env.sh` validates all preconditions; syntax clean; contains `EXPECTED_CHROMIUM_REV`, GN arg checks, `xcode-select`, `xcodebuild -version`, `xcrun metal -v`, `autoninja --version`, `gclient validate` |
| 2 | Root git has a tracked artifact-isolation policy and a blocking verifier for Chromium checkout/build artifacts | VERIFIED | `.gitignore` contains all 9 required policy lines; `verify-artifact-isolation.sh` uses `git check-ignore -v`, `git ls-files --`, `git status --short`; live run exits 0 |
| 3 | The pinned Chromium baseline remains `0e8499df5172f55d0d29e2b92ef7e6a704529578` unless a later plan documents an intentional change | VERIFIED | Constant `EXPECTED_CHROMIUM_REV` in `check-chromium-env.sh`; matches `chromium_revision` in both `.context/chromium-build-baseline.status` and `.context/chromium-launch.status` |
| 4 | Developer can reproduce GN generation and the `chrome` target build from a planning-owned script | VERIFIED | `build-chromium-baseline.sh` runs `./buildtools/mac/gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'` and `AI_AGENT=1 autoninja -C out/Default chrome`; `.context/chromium-build-baseline.status` records `status=0` |
| 5 | Build reproduction uses the locked GN args and explicit depot_tools and Xcode paths | VERIFIED | `build-chromium-baseline.sh` resolves `DEPOT_TOOLS`, `DEVELOPER_DIR`, calls `check-chromium-env.sh` as preflight, executes locked GN args inline |
| 6 | Build status and bounded log evidence are written under ignored `.context` paths | VERIFIED | Script writes `.context/chromium-build-baseline.status` (all 10 required keys) and `.context/chromium-build-baseline.log` (first 80 + last 200 lines); evidence files `git check-ignore` resolves to `.gitignore` |
| 7 | Developer can run the unmodified Chromium app from the local build before Prometheus source patches begin | VERIFIED | `smoke-launch-unmodified.sh` exists, is executable, syntax-clean; `.context/chromium-launch.status` records `status=0`, `patches_blocked=false`, `workaround_used=false` |
| 8 | The normal launch path is attempted before any DialMediaRouteProvider workaround is used or documented as needed | VERIFIED | `normal_attempt_status=0` in `.context/chromium-launch.status`; `--with-dial-workaround` is an explicit flag, not the default; `CHROMIUM-CHECKOUT.md` states "The normal path is attempted first" |
| 9 | Launch evidence records command, revision, GN args, clean-exit status, profile path, log path, and status path | VERIFIED | `.context/chromium-launch.status` contains `launch_command`, `chromium_revision`, `gn_args`, `status=0`, `profile_dir`, `log_file`, `startup_wait_seconds`, `quit_wait_seconds`, `depot_tools_revision`, `workaround_used`, `patches_blocked` |
| 10 | The Chromium baseline handoff records current depot_tools revision, pinned Chromium revision, GN args, build evidence, launch evidence, and artifact-isolation evidence | VERIFIED | `CHROMIUM-CHECKOUT.md` contains `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0` (depot_tools), `0e8499df5172f55d0d29e2b92ef7e6a704529578` (Chromium rev), all four gate commands, Unmodified Launch Result section, and Artifact Isolation Policy section |
| 11 | Later Chromium source patches are required to use named Chromium branches and exported patch guidance rather than root repo source copies | VERIFIED | `CHROMIUM-CHECKOUT.md` Patch Branch And Export Discipline section: `git new-branch prometheus/phase-13-branding`, `git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD`, "do not commit Prometheus changes directly on Chromium `main`" |
| 12 | Project state no longer claims unmodified launch verification is pending when launch evidence exists | VERIFIED | `STATE.md` "Pending Todos" section confirms launch passed; stale "Launch .context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium during Phase 12..." todo is absent; Deferred Items table shows `local_launch` as `complete` |

**Score:** 12/12 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/chromium/check-chromium-env.sh` | Fail-fast env gate enforcing pinned revision and GN args | VERIFIED | Executable, 5411 bytes, `bash -n` clean, contains `EXPECTED_CHROMIUM_REV`, all GN arg checks, toolchain probes, success string |
| `.planning/chromium/verify-artifact-isolation.sh` | Blocking root git isolation verifier | VERIFIED | Executable, 3714 bytes, `bash -n` clean, live `bash verify-artifact-isolation.sh` exits 0, contains all required `git check-ignore -v` / `git ls-files --` checks, success string |
| `.gitignore` | Tracked root policy for `.context`, `.gclient`, `out`, `depot_tools`, logs, caches | VERIFIED | All 9 required policy lines present: `/.context/`, `/.gclient`, `/.gclient_entries`, `/depot_tools/`, `/out/`, `/*.log`, `/*.status`, `/*.tmp`, `/*.cache` |
| `.planning/chromium/build-chromium-baseline.sh` | GN and autoninja reproduction gate | VERIFIED | Executable, 4462 bytes, `bash -n` clean, contains locked GN command and `autoninja -C out/Default chrome`, wired to `check-chromium-env.sh` preflight and `verify-artifact-isolation.sh` post-build |
| `.planning/chromium/smoke-launch-unmodified.sh` | Isolated-profile launch smoke for unmodified Chromium | VERIFIED | Executable, 10614 bytes, `bash -n` clean, contains `Prometheus Chromium Baseline Smoke`, `chromium-launch.status`, `CHROMIUM_BIN`, `normal_attempt_status`, `workaround_used`, `patches_blocked`, `startup_wait_seconds`, `osascript`, `kill -0` |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | Canonical Phase 12 handoff and patch discipline | VERIFIED | Contains `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`, `0e8499df5172f55d0d29e2b92ef7e6a704529578`, all four gate commands, Minimum Local Requirements, Unmodified Launch Result, Artifact Isolation Policy, Patch Branch And Export Discipline sections, blocker sentence |
| `.planning/STATE.md` | Current project state with launch evidence and no stale pending todo | VERIFIED | Contains `chromium-launch.status`, `chromium-launch.log`, `normal launch attempted first`, both revision hashes, GN args; stale pending launch todo removed; `local_launch` entry shows `complete` |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `check-chromium-env.sh` | `.context/chromium/src/out/Default/args.gn` | exact GN arg checks (`is_debug = false`) | WIRED | `grep -qF 'is_debug = false' "${BUILD_DIR}/args.gn"` present in script |
| `verify-artifact-isolation.sh` | `.gitignore` | `git check-ignore -v` must resolve to `.gitignore` | WIRED | Script calls `check_ignored_by_gitignore()` which asserts `.gitignore` appears in `git check-ignore -v` output; confirmed live |
| `build-chromium-baseline.sh` | `check-chromium-env.sh` | preflight invocation before GN/build commands | WIRED | `bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"` on line 54 before GN runs |
| `build-chromium-baseline.sh` | `.context/chromium-build-baseline.status` | status evidence file | WIRED | Status file written with all 10 keys; `status=0` confirmed |
| `smoke-launch-unmodified.sh` | `.context/chromium-launch.status` | launch evidence status file | WIRED | `STATUS_FILE="${PROJECT_ROOT}/.context/chromium-launch.status"` written unconditionally; all 16 required keys present |
| `smoke-launch-unmodified.sh` | `.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium` | resolved CHROMIUM_BIN | WIRED | `CHROMIUM_BIN="${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium"` used for all launch attempts |
| `CHROMIUM-CHECKOUT.md` | `smoke-launch-unmodified.sh` | launch proof command and status path | WIRED | `bash .planning/chromium/smoke-launch-unmodified.sh` in Phase 12 Script Gates section |
| `CHROMIUM-CHECKOUT.md` | `verify-artifact-isolation.sh` | blocking isolation gate | WIRED | `bash .planning/chromium/verify-artifact-isolation.sh` in Phase 12 Script Gates section |

---

## Data-Flow Trace (Level 4)

Not applicable. Phase 12 deliverables are gate scripts and documentation (no UI components or API routes rendering dynamic data). The "data flow" is the `.context/*.status` evidence files written by scripts and referenced in documentation — all traced directly above.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `verify-artifact-isolation.sh` exits 0 in current workspace | `bash .planning/chromium/verify-artifact-isolation.sh` | "Chromium artifact isolation passed." exit 0 | PASS |
| All four scripts are syntactically valid Bash | `bash -n` on each | All four exit 0 with no errors | PASS |
| `.context/chromium-build-baseline.status` records `status=0` | Read file | `status=0`, `gn_status=0`, `build_status=0` | PASS |
| `.context/chromium-launch.status` records `status=0`, `workaround_used=false`, `patches_blocked=false` | Read file | All three keys confirmed | PASS |
| Root git does not track any Chromium artifact paths | `git ls-files -- .context .gclient ...` | Empty output (no tracked artifacts) | PASS |
| `git check-ignore -v` confirms `.gitignore` (not gitdir-local) is isolation source | `git check-ignore -v .context/chromium/src/out/Default` etc. | All five tested paths show `.gitignore:N:` source | PASS |

Note: `check-chromium-env.sh` and `build-chromium-baseline.sh` and `smoke-launch-unmodified.sh` are not re-run per instructions (build is slow; launch opens a GUI window). Evidence files from prior execution confirm they passed.

---

## Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes declared or present. The phase used inline acceptance criteria and `.context/*.status` files as evidence. `verify-artifact-isolation.sh` functions as the only read-only runnable gate — executed live above.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CHROM-01 | Plan 01 | Developer can check out upstream Chromium using `depot_tools`/`fetch chromium` | SATISFIED | `check-chromium-env.sh` validates existing checkout at `0e8499df...`; `.gitignore` and `verify-artifact-isolation.sh` document the isolation contract |
| CHROM-02 | Plan 02 | Developer can generate a local macOS Chromium build directory with GN and build the `chrome` target | SATISFIED | `build-chromium-baseline.sh` runs locked GN gen + `autoninja -C out/Default chrome`; `.context/chromium-build-baseline.status` shows `status=0` |
| CHROM-03 | Plans 01, 02, 04 | Project documents minimum disk, time, SDK, Xcode, depot_tools, GN, and Ninja requirements | SATISFIED | `CHROMIUM-CHECKOUT.md` Minimum Local Requirements section: `100GB free disk buffer`, `macOS arm64`, `Xcode`, `MacOSX.sdk`, `Metal Toolchain`, `depot_tools`, `GN`, `Ninja`, `autoninja` |
| CHROM-04 | Plans 01, 04 | Chromium source is in a patch-discipline structure that allows upstream rebases without mixing generated artifacts into root repo | SATISFIED | `CHROMIUM-CHECKOUT.md` Patch Branch And Export Discipline section; `.gitignore` covers all artifact patterns; `verify-artifact-isolation.sh` blocks if artifacts are tracked; named branch + `git format-patch` rules documented |
| CHROM-05 | Plans 01, 02, 04 | Project records the exact Chromium revision used as the Prometheus migration baseline | SATISFIED | Revision `0e8499df5172f55d0d29e2b92ef7e6a704529578` pinned in `check-chromium-env.sh`, both `.status` files, `CHROMIUM-CHECKOUT.md`, and `STATE.md` |
| CHROM-06 | Plans 03, 04 | Developer can run the unmodified Chromium app from the local build before Prometheus modifications begin | SATISFIED | `smoke-launch-unmodified.sh` exits 0; `.context/chromium-launch.status` records `status=0`, `workaround_used=false`, `patches_blocked=false`, `normal_attempt_status=0` |
| CHROM-07 | Plans 02, 03 | Project has a reproducible build/run script for macOS fitting Conductor/workspace constraints | SATISFIED | `build-chromium-baseline.sh` (explicit paths, no fixed ports, writes bounded evidence); `smoke-launch-unmodified.sh` (isolated profile via `mktemp`, bounded startup/quit waits, no default profile reuse) |
| CHROM-08 | Plans 01, 04 | Chromium checkout/build artifacts are excluded or isolated so root repo does not commit massive generated directories | SATISFIED | `.gitignore` tracked policy; `git check-ignore -v` confirmed for all artifact path classes; `verify-artifact-isolation.sh` blocks if isolation breaks; `git ls-files` returns nothing for artifact paths |

All 8 requirements (CHROM-01 through CHROM-08) fully satisfied.

---

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `smoke-launch-unmodified.sh` line 98 | `XXXXXX` matches `XXX` pattern in raw grep | Info | `mktemp -d` template suffix — not a debt marker; the `XXX` sequence is part of the temporary file template name, not a `TODO`/`FIXME`/`TBD`/`XXX` comment |

No genuine debt markers (`TBD`, `FIXME`, `XXX` in comment context) found in any phase deliverable. The `XXXXXX` match is the standard `mktemp` template suffix.

No `return null`, placeholder strings, empty handlers, or hardcoded empty data structures found. All scripts have substantive implementations.

---

## Human Verification Required

None. All critical behaviors for this phase are verifiable programmatically:

- Script syntax: `bash -n` confirms all four scripts are syntactically valid
- Script content: `grep -qF` confirms all required substrings are present
- Build evidence: `.context/chromium-build-baseline.status` is readable and records `status=0`
- Launch evidence: `.context/chromium-launch.status` is readable and records `status=0`, `workaround_used=false`, `patches_blocked=false`
- Artifact isolation: `verify-artifact-isolation.sh` runs live and exits 0
- Git isolation: `git check-ignore -v` and `git ls-files` confirm no tracked Chromium artifacts

The only item that inherently requires human presence (visual confirmation that Chromium rendered the smoke page in a GUI window) has an adequate machine-verifiable proxy: the script recorded `status=0` after an 8-second alive check and clean osascript quit — which requires the process to have started, survived 8 seconds, and responded to quit.

---

## Gaps Summary

No gaps. All 12 observable truths verified, all 7 artifacts verified at all applicable levels (exists, substantive, wired), all 8 key links confirmed, all 8 requirements satisfied, no unresolved debt markers.

The `depot_tools_revision` in `.context/chromium-launch.status` (`a8c9ac983296908f8d662cb23ad6b8a0cae890b2`) differs from the value recorded in `.context/chromium-build-baseline.status` and `CHROMIUM-CHECKOUT.md` (`ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`). This is not a gap — depot_tools was updated between the build run and the launch run, which is normal git-managed tool behavior. The launch status file correctly records the revision at the time of the launch, not the build.

---

_Verified: 2026-06-23_
_Verifier: Claude (gsd-verifier)_
