---
phase: 21-supervision-pairing-and-remote-control
plan: 16
subsystem: chromium-supervision-tab-state
tags: [chromium, supervision, tab-state, observers, remote-control, privacy, tdd]

requires:
  - phase: 21-15
    provides: Authoritative browser-native controller and remote-action lifecycle with consent-first invalidation
  - phase: 21-04
    provides: Agent-owned exact-tab observation leases and sanitized supervision snapshots
provides:
  - Closed display-only supervision DTO in the existing browser-owned tab-state layer
  - Fresh exact-tab projection for viewers, controller, action, resync, availability, and severity
  - Coherent tab-state observer replacement before downstream supervision observer delivery
  - Terminal, owner-loss, shutdown, replacement, OTR, cross-profile, and cross-tab privacy regressions
affects: [21-17, 21-18, 21-19, 21-20, 21-22, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Browser chrome consumes one immutable display-only supervision value projected from the authoritative sanitized service snapshot
    - Exact Agent-owned observation leases carry projection updates without creating another owner or authority observer
    - Complete replacement and equality suppression prevent partial and duplicate display notifications

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep session, pairing, lease, owner, profile, browser, tab, document, sequence, URL, content, token, and raw action authority structurally absent from the chrome-facing supervision DTO."
  - "Publish the complete projected value through the service's exact Agent-owned tab observation lease before notifying service observers, with no reverse callback into supervision."
  - "Show eligible unowned view-only supervision independently of Agent ownership, but require the authoritative sanitized owner/controller shape before projecting controller or action state."
  - "Order controller first, disambiguate bounded safe labels, and derive display priority and severity from closed action and resync enums only."

patterns-established:
  - "Display projection is not authority: tab state maps an already-sanitized snapshot and never resolves owners, targets, documents, or credentials."
  - "Terminal replacement is coherent: controller/action authority is cleared by the owning service before one whole tab-state notification is observable."
  - "Safe display convergence: equal replacement values are suppressed, repeated terminal clears are harmless, and replacement tab data starts from the safe default."

requirements-completed: []
requirements-progressed: [SUP-03, SUP-04]

duration: 1h7min
completed: 2026-07-22
---

# Phase 21 Plan 16: Sanitized Supervision Tab State Summary

**Browser chrome now receives one fresh, bounded, authority-free supervision value from the exact Agent-owned tab data, with coherent controller/action teardown before observers render it.**

## Performance

- **Duration:** 1h7min
- **Started:** 2026-07-22T16:04:03Z
- **Completed:** 2026-07-22T17:11:06Z
- **Tasks:** 3
- **Files modified:** 10 source, test, build, and verifier files; 3 ordered patch exports

## Accomplishments

- Added closed view, control, activity, resync, severity, and action-category enums plus bounded viewer/controller display fields to `PrometheusTabState`; the DTO structurally cannot contain backend authority, page content, URLs, selectors, tokens, or raw action values.
- Implemented controller-first, duplicate-safe label projection with an authoritative bounded count, optional controller expiry, active-action priority, resync health, and fail-closed downgrade to view-only when Agent/controller conditions are not authoritative.
- Kept viewer visibility independent of Agent ownership so an eligible unowned tab can display supervision while controller/action fields remain impossible.
- Published each fresh service snapshot through the existing exact Agent-owned observation lease before service observers, without adding an owner observer, alternate authority calculation, fallback active tab, or reverse service callback.
- Replaced tab state atomically and idempotently, notified existing display observers only after whole-value replacement, invalidated them on tab-data destruction, and cleared the projection on terminal release and profile shutdown.
- Added lifecycle and privacy proofs for owner loss, repeated terminal clear, tab replacement, cross-tab isolation, OTR/cross-profile rejection, hostile labels, terminal-session omission, and service-publication ordering.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Specify sanitized tab supervision state and priority transitions** — nested `f0be3c5dc3`, root `40f50f854`, patch `0039`
2. **Task 2 (GREEN): Publish fresh service snapshots through tab state** — nested `ae51ea246d`, root `6086a05fe`, patch `0040`
3. **Task 3 (GREEN): Close stale, privacy, and teardown regressions** — nested `0f5712f190`, root `f93514537`, patch `0041`

## Files Created/Modified

- `prometheus_tab_state.h/.cc` — Display-only supervision DTO, observer contract, safe projector, closed enum mappings, bounded/disambiguated controller-first labels, and action/resync severity.
- `prometheus_agent_tab_data.h/.cc` — Exact browser-owned projection storage, whole-value equality suppression, coherent observer notification/invalidation, and unowned viewer visibility.
- `prometheus_supervision_profile_service.cc` — Exact observed-lease publication before service observers, resync/ack updates, and terminal/release/shutdown clears.
- `prometheus_agent_tab_data_unittest.cc` — Unowned view-only, coherent replacement, idempotence, owner-loss ordering, replacement, invalidation, and cross-tab isolation coverage.
- `prometheus_tab_state_unittest.cc` — Recursive structural privacy audit, controller/action priority, unowned downgrade, confirmation/resync/blocked state, hostile-label, and terminal omission coverage.
- `prometheus_supervision_profile_service_unittest.cc` — Actual service-to-tab publication order, controller teardown, OTR/cross-profile no-attachment, and hostile-label projection coverage.
- `chrome/browser/prometheus/BUILD.gn` — Projection type and exact service dependency wiring.
- `.planning/chromium/verify-phase-21.sh` — Exact tab-state object compilation/linking plus DTO privacy, dependency, and notification-order guards.
- `patches/0039` through `0041` — Stable ordered nested Chromium patch exports.

## Decisions Made

- The DTO contains only display-safe availability, bounded count/labels, optional controller label/expiry, and closed UI state/category/severity values. It intentionally cannot carry a stable tab, session, code, lease, owner, profile, browser, document, generation, sequence, URL, selector, content, raw value, argument, or token.
- `PrometheusSupervisionProfileService` remains the sole authority owner. It builds its existing sanitized snapshot once, updates only the exact observed Agent tab-data lease, then delivers that same snapshot to service observers.
- An authoritative controller requires an eligible target, a live Agent owner indication, a sanitized controller label, and an active controller session in the service snapshot. Any inconsistent or unowned shape is reduced to view-only and loses controller/action fields.
- Viewer count remains service-authoritative and hard-bounded, while visible labels include only active viewers, are sanitized again at the display boundary, are capped, and are deterministically disambiguated with the controller first.
- Owner loss relies on the existing invalidate-first service ordering: Agent ownership is cleared, the service terminalizes controller/action work, then the complete cleared projection is emitted. The display layer never terminalizes authority itself.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added service-path tab-state regressions**

- **Found during:** Task 3 lifecycle acceptance review
- **Issue:** The listed pure tab-data/tab-state files could prove projection and observer behavior but could not prove that the real profile service updates the exact lease before downstream observers or that rejected OTR/cross-profile targets attach no tab state.
- **Fix:** Extended the existing profile-service unit fixture with publication-order, owner-loss clearing, rejected-target no-attachment, and hostile-label tab-state assertions.
- **Verification:** Three focused service-path tests pass in the final linked binary, and the verifier statically compares update and service-observer line order.
- **Committed in:** `0f5712f190`

---

**Total deviations:** 1 auto-fixed missing-critical verification gap.
**Impact on plan:** The additional test-only coverage proves the planned exact service seam without expanding production authority or product scope.

## Issues Encountered

- The first RED run returned through an `ASSERT` before detaching a checked observer, so the intentionally failing suite also hit an observer-lifetime fatal. Making the observer outlive tab data produced the required assertion-only RED result.
- The first GREEN compile exposed a `string_view`/`string` concatenation mismatch, and Task 3 exposed Chromium's raw-pointer lint in a test helper. Both were corrected before runtime verification.
- An optional direct run of the pre-existing `RenderViewHostTestHarness` tab-state fixture hit the focused browser binary's existing uninitialized-Mojo startup limitation before any test body. The redundant new WebContents-only case was removed; the plan's pure tab-state suite and the real service-to-tab integration suite remain executable and green.

## Test Evidence

- RED gate: 8 focused supervision tests were selected and failed only their intended unimplemented projection assertions, with no crash, fatal, empty selection, or infrastructure failure.
- GREEN gate: the same 8 focused projection and Agent-tab-data tests passed after the projector, storage, observer, and service wiring landed.
- Final plan regression: all 15 requested `PrometheusAgentTabDataTest.*:PrometheusTabStateTest.*` tests passed after final source cleanup.
- Service-path regression: 3 focused profile-service tests passed for update-before-observer delivery, owner-loss controller/action clearing, OTR/cross-profile no attachment, and hostile-label sanitization.
- Compile-time concepts and verifier extraction prove forbidden authority, target, content, credential, and raw-value fields are structurally absent from the display DTO.
- Static guards prove the projector reads no owner/session authority, Agent tab data has no supervision-service callback edge, the exact service lease is updated before service observers, and the service target depends on the existing tab-state target.
- Exact object compiles, synthesized service/test compiles, focused linking, code signing, test discovery, verifier shell syntax, and root/nested `git diff --check` passed.
- Patch `0039` has stable patch ID `4c22b4fe8d4316a8b9c9dc934f6fe0b78882c8bc`, patch `0040` has `0ceaca7d91cfcb0bdc0b2ac09742ed14f0e4730a`, and patch `0041` has `8ddca132737dc8b4673a5edbf8eb35bdd29edf1b`; each matches its nested commit.
- Reviewed `.ninja_log`, `.ninja_deps`, Blink dylib, and Blink TOC hashes remained byte-identical throughout verification.

Human UAT was not run and is not claimed. Visible badge and side-panel consumers remain for Plans 21-17 and 21-18.

## User Setup Required

None. No credentials, packages, listeners, dashboards, or external configuration are required.

## Next Phase Readiness

Plan 21-17 can bind the native tab badge directly to `PrometheusTabState::Supervision`; it no longer needs to inspect the profile service, Agent owner IDs, controller leases, or raw dashboard snapshots.

SUP-03 and SUP-04 remain phase-level in progress until visible browser consumers, Control Panel lifecycle, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `f0be3c5dc3`, `ae51ea246d`, and `0f5712f190`
- FOUND: ordered root patches `0039`, `0040`, and `0041`
- VERIFIED: 8-test RED, 8-test GREEN, final 15-test requested regression, and 3-test service-path regression
- VERIFIED: display-only structural privacy, controller-first priority, unowned view-only behavior, coherent terminal replacement, exact-tab isolation, OTR/cross-profile rejection, patch identity, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
