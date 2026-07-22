---
phase: 21-supervision-pairing-and-remote-control
plan: 14
subsystem: chromium-supervision-action-control
tags: [chromium, supervision, agent, remote-control, authority, privacy, tdd]

requires:
  - phase: 21-13
    provides: Five native authority-free MCP supervision identities
  - phase: 18
    provides: Existing typed Agent action, permission, frame, actionability, verification, repeated-action, and audit engine
provides:
  - Closed remote-action classification with seven ordinary and three consequential categories
  - Exact Browser/tab/document/owner/controller/lease/epoch/sequence/generation admission around the existing Agent dispatcher
  - One bounded action/confirmation slot with lifecycle-first cancellation and late-callback fencing
  - Content-free supervision results and category/outcome/duration-only action activity and audit
affects: [21-15, 21-16, 21-23, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Remote control constructs only existing typed AgentRouteRequest values and enters through exact-browser dispatch
    - Browser-owned authority snapshots are resolved before construction, immediately before dispatch, and again at completion
    - Consequential work occupies one confirmation slot and must pass fresh authority validation before it can dispatch

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Treat click, type, key press, scroll, hover, select, and clear as ordinary; hold drag, drop, and navigation in the single consequential confirmation slot."
  - "Capture a nonempty redemption owner immutably and require exact live-owner equality; an empty or changed owner never claims or adopts authority."
  - "Require the request stamp to equal both the viewer's last acknowledgement and the hub's current browser-owned baseline before action admission."
  - "Expose no Agent payload or raw action values in supervision results, snapshots, or audit; only typed codes, category, outcome, and duration cross the boundary."

patterns-established:
  - "Exact-action dispatch: weak exact Browser plus stable tab and browser-resolved frame become one Agent target; profile-wide browser lookup is forbidden."
  - "Lifecycle invalidation: erase/reset controller authority and increment generation before cancelling pending action callbacks."
  - "Single-flight confirmation: a second action receives a typed controller conflict and no queue is created."

requirements-completed: []
requirements-progressed: [SUP-03, SUP-04]

duration: 1h20min
completed: 2026-07-22
---

# Phase 21 Plan 14: Typed Supervision Action Admission Summary

**Remote dashboard mutations now enter the unchanged typed Agent action engine only after exact owner/controller/browser/tab/document/stamp admission, with one bounded confirmation slot and teardown-safe callback fencing.**

## Performance

- **Duration:** 1h20min
- **Started:** 2026-07-22T13:06:00Z
- **Completed:** 2026-07-22T14:26:24Z
- **Tasks:** 3
- **Files modified:** 9 source, test, build, and verifier files; 3 ordered patch exports

## Accomplishments

- Added a closed action controller that rejects malformed, unknown, internal-surface, script-shaped, vault-shaped, stale, view-only, owner-mismatched, controller-conflicted, wrong-Browser, wrong-tab, and wrong-document requests before any Agent dispatch.
- Mapped all seven ordinary categories to their existing typed Agent routes with the immutable redemption owner and exact browser-derived target; no second renderer/DOM dispatcher or implicit ownership claim exists.
- Reserved drag, drop, and navigation for one consequential confirmation slot, with fresh validation before approval can dispatch and a typed conflict for every concurrent request.
- Revalidated Browser, profile, tab, live owner, controller session, lease, document epoch, sequence, and authority generation before construction, immediately before dispatch, and before accepting the Agent callback.
- Wired ack, enable, stop, revoke, expiry, owner loss, target loss, end, and profile shutdown so authority is invalidated before pending work is cancelled and late callbacks are harmless.
- Projected only action state/category and metadata-only requested/completed/blocked audit rows; raw text, option, key, ref, and URL values and Agent result payloads remain absent.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Specify supervision action admission** — nested `45b5a0cb02`, root `0789ceb95`, patch `0033`
2. **Task 2 (GREEN): Reuse typed Agent action dispatch** — nested `0019911281`, root `3c5b82e04`, patch `0034`
3. **Task 3 (GREEN): Fence supervision action lifecycle** — nested `d298276329`, root `853121d18`, patch `0035`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.h` — Content-free action authority/result types and the single-flight controller API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_action_controller.cc` — Closed classification, immutable authority, browser frame resolution, typed Agent request construction, cancellation, and completion fencing.
- `prometheus_supervision_action_controller_unittest.cc` — Named category, denial, exact-route, privacy, concurrency, confirmation, cancellation, and late-callback regressions.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h` — Dashboard action entry points and narrow dispatcher/callback declarations.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc` — Per-viewer controller lease, acknowledged stamp, action state, authority resolver, metadata-only audit, and lifecycle cancellation.
- `prometheus_supervision_profile_service_factory.cc` — Production injection of the narrow weak exact-browser Agent dispatcher.
- `prometheus_supervision_profile_service_unittest.cc` — View-only/unacknowledged, stop, navigation, owner-loss, revoke, expiry, shutdown, single-slot, and serialization privacy coverage.
- `BUILD.gn` — Action-controller source set and unit-test integration.
- `.planning/chromium/verify-phase-21.sh` — Synthesized action-controller compile/link support and static bypass/lifecycle guards.
- `patches/0033` through `0035` — Stable ordered nested Chromium patch exports.

## Decisions Made

- Ordinary classification is limited to the seven currently implemented typed page-action semantics. Drag, drop, and navigation are closed known categories but remain consequential; Plan 15 supplies the native confirmation UI before an allow-once continuation.
- Element and target refs are untrusted parameters. Production code derives the live frame/document from the redemption-bound Browser and stable tab, then the existing Agent engine repeats its own live-document and actionability checks.
- The controller never repairs authority. An empty redemption owner, later owner appearance, owner transition, missing lease, or stale stream terminates or blocks the old path; a new pairing is required.
- The supervision result deliberately omits free-form message, recovery, changed state, page result, and content. Agent denials cross only as `AgentErrorCode` plus a content-free action state.
- The current hub stamp must equal the viewer's last acknowledged stamp. This prevents a remote mutation from acting on a dashboard view that is already behind the browser-owned stream.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added factory composition outside the declared file list**

- **Found during:** Task 2 exact Agent seam implementation
- **Issue:** The controller could not reach `ExecuteBrowserLocalRoute` in production without either a forbidden profile-wide lookup or a narrow dispatcher supplied by keyed-service composition.
- **Fix:** Added a weak exact-browser dispatcher binder and injected it from `prometheus_supervision_profile_service_factory.cc`.
- **Files modified:** `prometheus_supervision_action_controller.cc`, `prometheus_supervision_profile_service_factory.cc`
- **Verification:** Static guard requires the binder and forbids profile-wide dispatch; factory and 34-test focused suites pass.
- **Committed in:** `0019911281` and `d298276329`

---

**Total deviations:** 1 auto-fixed blocking composition seam.
**Impact on plan:** Required to satisfy the plan's exact `ExecuteBrowserLocalRoute` key link without weakening profile or Browser authority; no public API or scope expansion.

## Issues Encountered

- The first verifier synthesis attempted to query an already synthesized profile object. Repointing the action compile to the real runtime-profile Ninja template produced a valid exact same-target compile command.
- Chromium forbids binding a returning member function directly through `base::WeakPtr`. The authority resolver now uses an explicit weak-checking lambda that returns `std::nullopt` after service destruction.
- Chromium's unsafe-buffer compiler check rejected indexed C arrays in the strengthened route-mapping test. `std::array::at()` retained the exact mapping assertion without suppressing the safety check.

## Test Evidence

- RED gate: 29 named action-controller tests selected; 16 intended admission/dispatch assertions failed normally, with no crash, fatal, empty selection, or infrastructure failure.
- Task 2 GREEN: 3 focused ordinary/Agent-denial/privacy tests selected and passed.
- Final GREEN: 34 controller and profile `Action*` tests selected and passed, including all ten categories, exact route/frame propagation, zero-dispatch denials, busy/confirmation, owner and document races, lifecycle cancellation, and raw-URL serialization privacy.
- Agent regressions: 7 existing Agent supervision and observation tests passed against the final focused binary.
- Static guards reject `ClaimIfUnowned`, profile-wide `ExecuteRoute`, alternate script/DOM dispatch, direct vault execution, missing lease/ack fences, missing lifecycle cancellation, and missing production Agent composition.
- All three exported patches have stable patch IDs identical to nested commits `45b5a0cb02`, `0019911281`, and `d298276329`.
- Root and nested `git diff --check`, verifier shell syntax, exact service/factory/controller/test compiles, focused link, test discovery, code signing, and reviewed Ninja/Blink artifact hashes passed.

Human UAT was not run and is not claimed. Native consequential/control consent is intentionally completed by Plan 21-15.

## User Setup Required

None. No credentials, packages, listeners, dashboards, or external configuration are required.

## Next Phase Readiness

Plan 21-15 can attach native control and consequential-action dialogs to the controller's single confirmation slot. Every allow-once continuation already performs fresh owner/controller/Browser/tab/document/stamp/generation validation before typed Agent dispatch.

SUP-03 and SUP-04 remain phase-level in progress until native consent, UI projection, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `45b5a0cb02`, `0019911281`, and `d298276329`
- FOUND: ordered root patches `0033`, `0034`, and `0035`
- VERIFIED: 34-test final controller/profile gate and 7-test Agent regression
- VERIFIED: exact typed dispatch, lifecycle cancellation, privacy guards, patch identity, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
