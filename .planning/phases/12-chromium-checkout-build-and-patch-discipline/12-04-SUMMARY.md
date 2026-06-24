---
phase: "12-chromium-checkout-build-and-patch-discipline"
plan: "04"
subsystem: "chromium-baseline-handoff"
tags: ["chromium", "handoff", "patch-discipline", "documentation", "state-reconciliation"]
dependency_graph:
  requires:
    - ".planning/chromium/check-chromium-env.sh: Plan 01 environment gate"
    - ".planning/chromium/build-chromium-baseline.sh: Plan 02 build gate"
    - ".planning/chromium/smoke-launch-unmodified.sh: Plan 03 launch gate"
    - ".planning/chromium/verify-artifact-isolation.sh: Plan 01 isolation gate"
    - ".context/chromium-build-baseline.status: Plan 02 build evidence"
    - ".context/chromium-launch.status: Plan 03 launch evidence"
  provides:
    - ".planning/chromium/CHROMIUM-CHECKOUT.md: Canonical Phase 12 Chromium baseline handoff and patch discipline"
    - ".planning/STATE.md: Project state with launch proof and downstream blocker resolution"
  affects:
    - "Phase 13+: handoff defines patch branch/export discipline; launch evidence unblocks Prometheus source patches"
tech_stack:
  added: []
  patterns:
    - "Evidence citation from ignored .context/ status files into tracked planning docs"
    - "Patch discipline documented as named-branch + git format-patch export from pinned baseline"
key_files:
  created: []
  modified:
    - ".planning/chromium/CHROMIUM-CHECKOUT.md"
    - ".planning/STATE.md"
decisions:
  - "Record depot_tools revision as ea253a3e3ae7653cafd343be001dc5cbe69b3ad0 (build-time snapshot from chromium-build-baseline.status)"
  - "Frame workaround --disable-features=DialMediaRouteProvider as explicit retry only; normal-path-first framing is the canonical proof"
  - "Tracked .gitignore policy (not gitdir-local exclude) is the isolation contract for fresh-clone reproducibility"
  - "Patch export from pinned baseline 0e8499df5172f55d0d29e2b92ef7e6a704529578 with git format-patch is the discipline for all future Prometheus Chromium source changes"
  - "Phase 12 complete: launch status=0, workaround_used=false, patches_blocked=false confirms Phase 13 is unblocked"
metrics:
  duration: "10 minutes"
  completed_date: "2026-06-24"
  tasks: 2
  files_created: 0
  files_modified: 2
---

# Phase 12 Plan 04: Chromium Baseline Handoff and State Reconciliation Summary

**One-liner:** CHROMIUM-CHECKOUT.md updated as canonical Phase 12 handoff with all four gate commands, exact revisions, locked GN args, normal-path-first launch proof, artifact isolation policy, and named-branch patch discipline; STATE.md replaced the pending launch todo with completed evidence and unblocked Phase 13.

## What Was Built

### Task 1: CHROMIUM-CHECKOUT.md — Canonical Phase 12 Handoff

`.planning/chromium/CHROMIUM-CHECKOUT.md` was rewritten in place as the canonical handoff for Phase 13 and all later Chromium work. Changes from the previous version:

**Baseline Identity block (new):**

```text
Chromium revision: 0e8499df5172f55d0d29e2b92ef7e6a704529578
depot_tools revision: ea253a3e3ae7653cafd343be001dc5cbe69b3ad0
GN args: is_debug=false is_component_build=true symbol_level=0
Build gate: bash .planning/chromium/build-chromium-baseline.sh --no-op-ok
Launch gate: bash .planning/chromium/smoke-launch-unmodified.sh
Isolation gate: bash .planning/chromium/verify-artifact-isolation.sh
Future branch example: git new-branch prometheus/phase-13-branding
Patch export command includes: git format-patch
```

**Minimum Local Requirements section (new):** Explicitly names 100GB free disk buffer, macOS arm64, Xcode, MacOSX.sdk, Metal Toolchain, depot_tools, GN, Ninja, autoninja, and `fetch --no-history chromium` as required. Includes locked GN args as a single inline string `is_debug=false is_component_build=true symbol_level=0`.

**Phase 12 Script Gates section (new):** Lists all four gate scripts in order with brief purpose descriptions. Each script is described as fail-fast with concrete remediation.

**Unmodified Launch Result section (new):** Records launch evidence from `.context/chromium-launch.status`:

```text
attempt=normal
normal_attempt_status=0
workaround_used=false
status=0
patches_blocked=false
log_file: .context/chromium-launch.log
status_file: .context/chromium-launch.status
```

Frames the normal path as the baseline proof. The `--disable-features=DialMediaRouteProvider` workaround is documented as an explicit retry option for repeated macOS local network permission prompt noise, not presented as the default proof.

**Artifact Isolation Policy section (new):** Describes the tracked `.gitignore` approach and names `verify-artifact-isolation.sh` as the blocking gate before accepting build or launch evidence.

**Patch Branch And Export Discipline section (new):** Specifies that:

- Source edits happen inside `.context/chromium/src` only
- Root repo stores docs, scripts, evidence, and exported patch guidance only
- Named branches are required (`git new-branch prometheus/phase-13-branding`)
- Patches are exported with `git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD`
- After rebases: run `gclient sync`, `gn gen`, build, launch smoke, and artifact isolation again
- GPL Falkon source must not be copied into `.context/chromium/src` without license review

**Downstream blocker sentence (exact):** If `.context/chromium-launch.status` records `patches_blocked=true` or a nonzero status, Prometheus-specific Chromium patches are blocked until the launch blocker is fixed or explicitly documented.

**depot_tools revision updated:** Previous version recorded `c46c2e905` (short hash from Phase 11 research). Updated to full hash `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0` from `.context/chromium-build-baseline.status`.

### Task 2: STATE.md — Launch Evidence and Phase 12 Completion

`.planning/STATE.md` was updated to reflect that Phase 12 is complete and that launch verification passed:

**Pending Todos:** Replaced the pending action `Launch .context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium during Phase 12 to verify the unmodified Chromium app before Prometheus patches begin` with a completed-state sentence confirming `.context/chromium-launch.status` records `status=0`, `workaround_used=false`, `patches_blocked=false`.

**Accumulated Decisions (new):**

- Phase 12 launch verification passed; normal launch attempted first; evidence at `.context/chromium-launch.status` and `.context/chromium-launch.log`; all baseline identity terms recorded.
- Phase 12 artifact isolation verified via `verify-artifact-isolation.sh`.
- Phase 12 patch discipline documented in `CHROMIUM-CHECKOUT.md`.
- Milestone v2.0 depot_tools revision updated from `c46c2e905` to `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`.

**Blockers/Concerns:** Removed the stale item `first chrome build finished successfully and still needs Phase 12 launch verification`. Replaced with `Phase 12 complete; Phase 13 may begin`.

**Deferred Items table:** Marked `build_finished_launch_pending` row as `complete`; added `local_launch` row recording the completed launch verification.

**Current Position:** Updated to `COMPLETE — 4 of 4 plans done`.

**Operator Next Steps:** Rewritten to point toward Phase 13 branch creation and patch work.

## Verification

All Task 1 acceptance criteria passed:

- `rg 'ea253a3e3ae7653cafd343be001dc5cbe69b3ad0' .planning/chromium/CHROMIUM-CHECKOUT.md` — match found
- `rg '0e8499df5172f55d0d29e2b92ef7e6a704529578' .planning/chromium/CHROMIUM-CHECKOUT.md` — match found
- `rg '100GB free disk buffer|MacOSX.sdk|Metal Toolchain|depot_tools|GN|Ninja|autoninja|fetch --no-history chromium' .planning/chromium/CHROMIUM-CHECKOUT.md` — all terms found
- `rg 'bash .planning/chromium/check-chromium-env.sh|bash .planning/chromium/build-chromium-baseline.sh --no-op-ok|bash .planning/chromium/smoke-launch-unmodified.sh|bash .planning/chromium/verify-artifact-isolation.sh' .planning/chromium/CHROMIUM-CHECKOUT.md` — all four gate commands found
- `rg 'normal path is attempted first|--disable-features=DialMediaRouteProvider|workaround_used|patches_blocked|.context/chromium-launch.status|.context/chromium-launch.log' .planning/chromium/CHROMIUM-CHECKOUT.md` — all launch evidence terms found
- `rg 'git new-branch prometheus/phase-13-branding|git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD|do not commit Prometheus changes directly on Chromium|.context/chromium/src' .planning/chromium/CHROMIUM-CHECKOUT.md` — all patch discipline terms found

All Task 2 acceptance criteria passed:

- `rg 'chromium-launch.status|chromium-launch.log|normal launch attempted first' .planning/STATE.md` — all found
- `rg '0e8499df5172f55d0d29e2b92ef7e6a704529578|ea253a3e3ae7653cafd343be001dc5cbe69b3ad0|is_debug=false is_component_build=true symbol_level=0' .planning/STATE.md` — all found
- Old pending todo (Launch during Phase 12) is no longer in STATE.md

## Deviations from Plan

None. Plan executed exactly as written.

## Known Stubs

None. Both documents cite real evidence from `.context/chromium-launch.status` and `.context/chromium-build-baseline.status`. No placeholder text, hardcoded empty values, or unwired data sources.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries were introduced in this plan. Both files reference `.context/` status file paths and values only; full logs remain in the ignored `.context/` directory.

The CHROMIUM-CHECKOUT.md handoff explicitly separates the Falkon GPL implementation from Chromium (different license structures) and restricts source copying to explicit license review only. This preserves the GPL/Chromium license boundary required by PROJECT.md.

No new threat flags beyond those already covered in the plan's STRIDE threat register (T-12-19 through T-12-24).

## Requirements Addressed

- CHROM-03: Minimum local requirements (Xcode, MacOSX.sdk, Metal Toolchain, depot_tools, GN, Ninja, autoninja) are documented with exact install commands in CHROMIUM-CHECKOUT.md.
- CHROM-04: Patch discipline defined: named branches in `.context/chromium/src`, `git format-patch` export from pinned baseline, root repo stores docs and patch guidance only.
- CHROM-05: Pinned baseline revision `0e8499df5172f55d0d29e2b92ef7e6a704529578` and exact depot_tools revision `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0` recorded in the handoff.
- CHROM-06: Unmodified Chromium launch verified (status=0, workaround_used=false, patches_blocked=false) before Prometheus patches begin. Evidence in CHROMIUM-CHECKOUT.md and STATE.md.
- CHROM-08: Artifact isolation policy and blocking `verify-artifact-isolation.sh` gate documented in CHROMIUM-CHECKOUT.md.

## Self-Check: PASSED

Files exist:

- `.planning/chromium/CHROMIUM-CHECKOUT.md` — FOUND (modified)
- `.planning/STATE.md` — FOUND (modified)

Commits exist:

- `5537486c8` (docs(12-04): finalize Chromium baseline handoff) — FOUND
- `6e697c5c4` (docs(12-04): reconcile project state with Phase 12 launch and isolation evidence) — FOUND
