---
phase: 22-chrome-extension-ecosystem-and-policy
plan: 01
subsystem: browser-policy
tags: [chromium, extensions, keyed-service, prefs, registry]

requires:
  - phase: 21-supervision-pairing-and-remote-control
    provides: Browser-owned authority, profile-keyed services, bounded snapshots, and stable nested-patch preservation
provides:
  - Deny-by-default regular-profile extension policy service with separate regular and Private grants
  - Bounded schema-versioned grant persistence and sanitized generation-stamped inventory snapshots
  - ExtensionRegistry lifecycle reconciliation with stale-generation rejection and uninstall erasure
  - Focused metadata-preserving Phase 22 policy verifier and four stable Chromium patches
affects: [22-02-extension-surfaces, 22-03-control-panel-policy, 22-04-extension-fixtures, 22-05-extension-smoke]

tech-stack:
  added: []
  patterns:
    - Chromium ExtensionRegistry remains lifecycle authority while Prometheus persists policy choices only
    - Effective access is freshly derived from registry state, native eligibility, and separate bounded requested grants
    - Generation invalidation precedes observer notification for every lifecycle mutation

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_types.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_prefs.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service_factory.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service_unittest.cc
    - .planning/chromium/verify-phase-22-extension-policy.sh
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prefs/browser_prefs.cc

key-decisions:
  - "Persist only bounded requested grant choices keyed by Chromium-owned extension IDs; derive enabled state and effective access from a fresh registry lookup."
  - "Keep Private access separately requested, default Blocked, capped by regular access, and conditional on native Private eligibility."
  - "Invalidate snapshot generation before lifecycle notification and physically erase persisted grants on uninstall so stale rows cannot regain authority."

patterns-established:
  - "Policy-choice/lifecycle split: Prometheus owns bounded choices; Chromium owns installation identity and lifecycle."
  - "Sanitized inventory: local rows expose bounded names and ID suffixes, while external health remains inventory-free."
  - "Stable nested patch chain: every retained Chromium RED/GREEN commit has one ordered source-only export."

requirements-completed: [EXT-01, EXT-03]

duration: 47 min
completed: 2026-07-28
---

# Phase 22 Plan 01: Extension Policy Foundation Summary

**Browser-owned extension policy with deny-by-default regular/Private grants, bounded persistence, sanitized generation-stamped snapshots, and fail-closed registry lifecycle reconciliation**

## Performance

- **Duration:** 47 min
- **Started:** 2026-07-28T22:19:16Z
- **Completed:** 2026-07-28T23:06:07Z
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments

- Added a regular-profile keyed policy service that persists only closed, bounded grant choices and derives effective access from current Chromium registry truth.
- Kept regular and Private access independent: both default Blocked, Private never exceeds regular, and native Private eligibility is required at evaluation time.
- Reconciled ready/install/enable/disable/terminate/reload/uninstall/replacement/shutdown events by ID with generation fencing, stale-row rejection, and physical uninstall cleanup.
- Retained four ordered source-only Chromium patches and a focused runner that proves the selected cohort is nonempty while preserving Ninja metadata.

## Task Commits

Each task was committed atomically in both the root coordination repository and nested Chromium repository:

1. **Task 1: Scaffold focused runner and retain policy RED contract**
   - Root: `7b3b8cd52`
   - Chromium: `1467153d80`
2. **Task 2: Implement bounded persistence, snapshots, health, and Private-separated grants**
   - Root: `36985bbfe`
   - Chromium: `7ff294f811`
3. **Task 3: Reconcile registry lifecycle without stale pointers or authority resurrection**
   - RED root: `11a5bb05a`
   - RED Chromium: `2a99bf234c`
   - GREEN root: `81e8bc077`
   - GREEN Chromium: `f3cdfca50e`

## Files Created/Modified

- `.planning/chromium/verify-phase-22-extension-policy.sh` - Guarded direct runner for focused, expected-failure, lifecycle, hash-preservation, and patch-chain checks.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_types.{h,cc}` - Closed grant, row, snapshot, health, and bounds contracts.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_prefs.{h,cc}` - Schema-versioned bounded preference registration and parsing.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service.{h,cc}` - Regular-profile policy owner, effective-grant evaluator, generation fencing, and registry reconciliation.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service_factory.{h,cc}` - Regular-profile keyed-service composition with Chromium extension-system dependencies.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_policy_service_unittest.cc` - Closed-contract, bounds, privacy, OTR, registry, lifecycle, reentrancy, and shutdown coverage.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Policy sources, dependencies, and retained test registration.
- `.context/chromium/src/chrome/browser/prefs/browser_prefs.cc` - Prometheus extension policy profile-pref registration.
- `.planning/phases/22-chrome-extension-ecosystem-and-policy/patches/0001-*.patch` through `0004-*.patch` - Ordered stable source-only Chromium exports.

## Decisions Made

- Persist only requested policy choices; never persist installed names, permissions, origins, page content, profile paths, runtime handles, or effective authority.
- Resolve extension IDs against the current registry before every snapshot or mutation and expose only a sanitized suffix in local rows.
- Advance generation before notifying observers, remove grant state before uninstall notification, and make late shutdown callbacks harmless.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The sequential executor twice failed to return after making forward progress. GSD stall recovery preserved all atomic commits; the orchestrator then ran the complete focused and lifecycle gates and produced this closeout. No product implementation or verification blocker remained.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash .planning/chromium/verify-phase-22-extension-policy.sh --focused` selected and passed 21/21 runnable policy tests.
- `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='PrometheusExtensionPolicy*Registry*:*Lifecycle*'` passed 6/6 exact lifecycle tests.
- The focused runner reported identical before/after SHA-256 hashes for `.ninja_log` and `.ninja_deps`.
- Root and nested Chromium `git diff --check` both passed; the nested Chromium worktree is clean.

## Next Phase Readiness

- The policy truth layer is ready for Plan 22-02 to add a separate, fail-closed Agent transport for visible extension popup and side-panel surfaces.
- No blockers remain.

## Self-Check: PASSED

- Key policy service, factory, pref, type, verifier, and unit-test files exist.
- All eight root/nested task commits are present.
- Complete focused and exact lifecycle acceptance cohorts pass.
- Metadata preservation and stable patch-chain checks pass.

---
*Phase: 22-chrome-extension-ecosystem-and-policy*
*Completed: 2026-07-28*
