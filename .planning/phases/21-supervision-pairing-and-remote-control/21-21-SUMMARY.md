---
phase: 21-supervision-pairing-and-remote-control
plan: 21
subsystem: chromium-control-panel-supervision-lifecycle
tags: [chromium, supervision, pairing, webui, lifecycle, native-dialog, privacy, tdd]

requires:
  - phase: 21-20
    provides: Exact-window sanitized Control Panel snapshots and one-shot pairing creation
  - phase: 21-15
    provides: Native one-way supervision approval with fresh backend revalidation
provides:
  - Exact-row enable, stop, revoke, end, retry, and cancellation lifecycle routing
  - Fresh sanitized service observation after authority invalidation
  - Consumer-local baseline retry without renderer-supplied cursor or stream authority
  - Idempotent pairing-presentation erasure across redemption, cancel, replace, reload, target loss, and shutdown
  - Physical expiry and shutdown erasure of retained pairing digests before observer completion
affects: [21-22, 21-23, 21-24, 21-25, 21-26, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Browser-only row bindings pair an opaque dashboard token with exact weak target and authority generation
    - One code-free presentation binding converges all terminal and runtime-loss paths on idempotent invalidation
    - Capture-hub baseline retry mutates only the selected opaque consumer

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Treat every connected-row ordinal as a one-generation display reference and re-resolve its exact Browser, tab, dashboard token, owner, and authority generation before mutation."
  - "Keep pairing presentation state code-free in the native adapter and invalidate it before cancellation, replacement, terminal observer delivery, reload/disconnect, target loss, or shutdown."
  - "Retry baseline through the selected capture-hub consumer only; never force a shared baseline or accept renderer epoch, sequence, or cursor authority."
  - "Erase expired and shutdown pairing digests before observers run while retaining only bounded terminal metadata."

patterns-established:
  - "Lifecycle observer ordering: invalidate controller/viewer/capture/pairing authority first, then rebuild and publish a complete sanitized snapshot."
  - "Presentation erasure: clear the direct WebUI result and native binding once; duplicate or late terminal callbacks become harmless no-ops."
  - "Strict destructive intent: revoke and target-wide end require exactly [ordinal, true], while enable, stop, and retry require exactly [ordinal]."

requirements-completed: [SUP-01, SUP-03, SUP-04, SUP-05]

duration: 2h04min
completed: 2026-07-24
---

# Phase 21 Plan 21: Exact Control Panel Lifecycle and Terminal Erasure Summary

**The Control Panel now routes supervision lifecycle actions through fresh exact native authority while every terminal or runtime-loss boundary erases one-shot pairing presentation and retained digest state.**

## Performance

- **Duration:** 2h04min
- **Started:** 2026-07-24T16:34:15Z
- **Completed:** 2026-07-24T18:38:00Z
- **Tasks:** 3
- **Files modified:** 12 source, test, and verifier files; 3 ordered patch exports

## Accomplishments

- Added strict bounded WebUI messages for enable, stop, revoke, end-target, retry-baseline, and cancel-presentation, with malformed or extra arguments remaining non-mutating.
- Bound connected rows to weak exact tabs, tab handles, opaque dashboard sessions, service authority generations, and runtime generations held only in native memory.
- Routed enable through the existing Plan 15 native dialog and revalidated target, owner, session, generation, and document state after approval.
- Made stop immediate, revoke and target-wide end explicit, and all lifecycle mutations publish fresh sanitized state only after authority invalidation.
- Added a capture-hub retry seam that marks only the selected dashboard consumer baseline-required without accepting or advancing caller cursor, epoch, or sequence state.
- Converged redemption, cancellation, replacement, reload/WebUI destruction, target loss, and service shutdown on one idempotent code-free presentation invalidation path.
- Physically erased expired and shutdown pairing digest records before observer completion while preserving bounded terminal state and the existing expired-code response.
- Added real WebUI/native-dialog/service tests for exact actions, stale confirmation, observer ordering, two-viewer retry isolation, reload and replacement races, target loss, shutdown, and recursive code/authority privacy.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Freeze lifecycle actions, observer ordering, and erasure boundaries** — nested `914ee49be9`, root `e92af618f`, patch `0054`
2. **Task 2 (GREEN): Route exact-row lifecycle actions and native approval** — nested `46b156ba37`, root `3f2d50d63`, patch `0055`
3. **Task 3 (GREEN): Erase terminal pairing presentation and digest state** — nested `26272ff410`, root `cca571bf8`, patch `0056`

## Files Created/Modified

- `prometheus_side_panel_runtime.h/.cc` — Closed lifecycle virtuals and callback seam for code-free presentation invalidation.
- `prometheus_web_ui.h/.cc` — Exact message registration/parsing, operation delivery, and renderer presentation clearing.
- `prometheus_browser_main_extra_parts.cc` — Exact connected-row bindings, lifecycle routing, fresh service observation, native approval reuse, and idempotent presentation teardown.
- `prometheus_supervision_capture_hub.h/.cc` — Consumer-local baseline request that does not force or advance sibling consumers.
- `prometheus_supervision_profile_service.h/.cc` — Local-UI row projection/revalidation, lifecycle service seams, shutdown ordering, and terminal digest erasure.
- `prometheus_supervision_profile_service_unittest.cc` — Expiry erasure, two-viewer retry isolation, and shutdown observer-order regressions.
- `prometheus_web_ui_browsertest.cc` — Exact lifecycle actions, stale native-dialog race, sanitized event ordering, and terminal/reload/disconnect presentation erasure.
- `.planning/chromium/verify-phase-21.sh` — Closed lifecycle RED allowlist plus source guards for exact rows, consumer-local retry, observer ordering, and digest erasure evidence.
- `patches/0054` through `0056` — Stable ordered nested Chromium patch exports.

## Decisions Made

- Renderer ordinals remain display references only. The native adapter owns the opaque dashboard token and exact weak target, and each action must survive generation, handle, list, Browser, profile, target, owner, and service revalidation.
- A pending presentation binding stores no raw or formatted code. Its callback clears the direct WebUI result before native cancellation or terminal publication, and repeated invalidations do nothing.
- Baseline retry calls `RequestBaseline` for one capture consumer. It never uses the hub's force-baseline path, so another dashboard or Agent-compatible consumer keeps its own acknowledged cursor and readable state.
- Shutdown now invalidates weak callbacks, controllers, viewers, action controllers, capture consumers/hubs, pending digests, and observed tab state before notifying service observers.
- Expiry records the bounded terminal state and audit entry but erases the salted digest before publishing the observer snapshot.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added the capture-hub consumer-local retry seam**

- **Found during:** Task 2 exact retry implementation
- **Issue:** The declared files did not include the capture hub, but the service had no safe way to mark exactly one consumer baseline-required without using a shared recapture path.
- **Fix:** Added `RequestBaseline(consumer_id)` to the hub and kept forced shared baseline generation disabled when a usable baseline already exists.
- **Files modified:** `prometheus_supervision_capture_hub.h`, `prometheus_supervision_capture_hub.cc`
- **Verification:** `ControllerRetryBaselineMarksOnlyRequestedDashboardConsumer` passed with two independent dashboard consumers.
- **Committed in:** `46b156ba37`

**2. [Rule 2 - Missing Critical] Added service-level terminal and retry regressions**

- **Found during:** Task 3 erasure and isolation review
- **Issue:** Browser coverage proved presentation behavior but could not directly prove physical digest removal, full pre-observer backend teardown, or sibling-consumer cursor isolation.
- **Fix:** Added a count-only digest test seam and focused Pairing/Controller unit regressions for expiry, shutdown ordering, and two-viewer retry.
- **Files modified:** `prometheus_supervision_profile_service.h`, `prometheus_supervision_profile_service.cc`, `prometheus_supervision_profile_service_unittest.cc`
- **Verification:** All 11 focused `Pairing*` and `Controller*` service tests passed.
- **Committed in:** `26272ff410`

---

**Total deviations:** 2 auto-fixed (2 missing critical security/regression seams).
**Impact on plan:** Both changes were necessary to prove the requested consumer-local and unrecoverable-erasure guarantees; no renderer authority or product scope was added.

## Issues Encountered

- The first RED browser process treated unregistered lifecycle messages as fatal; closed `NOT_READY` stubs were added so the expected-failure gate reached only the three intended assertions.
- Chromium appends a parameter suffix to typed browser-test failure names; the RED verifier parser was tightened to accept that suffix while continuing to reject unrelated failures or crashes.
- The initial observer race assertion retained an earlier enable-operation event; clearing the test event buffer immediately before revoke made the assertion inspect the intended invalidate-before-operation boundary.

## Test Evidence

- Task 1 RED selected exactly 3 lifecycle browser tests and failed only their named unimplemented assertions, with no crash/fatal output.
- Task 2 selected 3 lifecycle/native-dialog browser tests and passed exact action routing, strict malformed-input rejection, native approval, and code-free snapshot/event checks.
- Task 3 final browser gate selected all 3 `SupervisionRuntimeLifecycle*` tests and passed exact actions, stale-dialog invalidation, observer ordering, redemption, duplicate cancel, reload/disconnect, replacement, target loss, and shutdown erasure.
- The final service gate selected all 11 `Pairing*` and `Controller*` tests and passed one-use, expiry, bounded attempts, exact controller authority, consumer-local retry, and post-erasure shutdown observation.
- Root and nested `git diff --check` passed.
- Reviewed hashes stayed byte-identical: `.ninja_log` `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`, `.ninja_deps` `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`, Blink dylib `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`, Blink TOC `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`, and framework `resources.pak` `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`.
- Patches `0054`, `0055`, and `0056` have stable patch IDs `6cf4b530a0090eb359aa906cc0e216204a4f34d1`, `d67007ab42b41024c49022249bff4fd8434e449e`, and `ea46239df9d6c88b8590aaf60bae38f4e7ee5449`; each matches its nested commit.
- Applying `0054–0056` in order to nested base `ab3c5fe80a` produced tree `bb72e7adc37edb3f6504cb9979e49ad4d0ede707`, exactly matching nested commit `26272ff410`.

## User Setup Required

None. No credentials, packages, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-22 can render the responsive Supervision & Pairing UI against complete exact-row lifecycle operations, fresh sanitized observer snapshots, and an idempotent one-shot presentation-erasure contract.

No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `914ee49be9`, `46b156ba37`, and `26272ff410`
- FOUND: root task commits `e92af618f`, `3f2d50d63`, and `cca571bf8`
- FOUND: ordered patches `0054`, `0055`, and `0056`
- VERIFIED: 3-test RED, 3-test lifecycle/native-dialog GREEN, final 3-test lifecycle browser gate, and final 11-test Pairing/Controller service gate
- VERIFIED: exact action revalidation, code-free snapshots/events, consumer-local retry, every terminal presentation boundary, physical digest erasure, patch identity/replay, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
