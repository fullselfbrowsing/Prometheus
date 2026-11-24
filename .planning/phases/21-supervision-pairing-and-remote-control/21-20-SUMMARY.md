---
phase: 21-supervision-pairing-and-remote-control
plan: 20
subsystem: chromium-control-panel-supervision-runtime
tags: [chromium, supervision, pairing, webui, privacy, exact-window, tdd]

requires:
  - phase: 21-19
    provides: Persistent side-panel supervision state and zero-authority actions
  - phase: 21-18
    provides: Exact-tab native supervision runtime and selected-tab lifecycle bridge
provides:
  - Closed Control Panel supervision snapshot DTOs with bounded display-only rows
  - Exact regular Browser target enumeration and generation-bound weak ordinal revalidation
  - Strict select, create, replace, and cancel-presentation WebUI messages
  - One-shot formatted pairing-code result isolated from snapshots and routine operations
  - Explicit replacement-required behavior with old-digest-first invalidation
affects: [21-21, 21-22, 21-23, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Distinct native snapshot and create-result types make the direct create callback the sole code-capable channel
    - Renderer ordinals index one generation of weak exact-window targets and are revalidated before every mutation
    - Ordinary create preserves an existing pending digest until explicit replacement invalidates it

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep formatted_code exclusively on PrometheusControlSupervisionCreateResult; snapshot, connected, recent, audit, target, and ordinary-operation DTOs cannot represent it."
  - "Bind the Control Panel runtime to the Browser containing its exact WebContents, list only that normal window's eligible HTTP(S) pages, and never silently select a replacement after target loss."
  - "Treat renderer ordinals as display-only references to one native generation; weak target, handle, list membership, Browser, profile, URL eligibility, and generation are checked again at action time."
  - "Require an explicit replace message when a pending digest exists, and erase the old digest before generating the next code."
  - "Format the eight-character raw code only for the direct result, then zero-fill and clear the unformatted native buffer immediately."

patterns-established:
  - "Closed supervision transport: regular snapshots expose targets, selected display state, connected/recent rows, and audit metadata under fixed caps without native identity fields."
  - "Replacement transaction: duplicate create is non-mutating and replacement-required; explicit replacement invalidates old authority before new bearer generation."
  - "One-shot WebUI delivery: create and replace use a dedicated callback while refresh, observer, select, cancellation, diagnostics, and routine operations remain code-incapable."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-03, SUP-04, SUP-05]

duration: 1h20min
completed: 2026-07-24
---

# Phase 21 Plan 20: Sanitized Control Panel Snapshot and One-Shot Pairing Summary

**The Control Panel now receives exact-window, display-only supervision state and can create or explicitly replace one ephemeral pairing code through a dedicated direct result without exposing bearer material to normal observation.**

## Performance

- **Duration:** 1h20min
- **Started:** 2026-07-24T15:08:06Z
- **Completed:** 2026-07-24T16:27:58Z
- **Tasks:** 3
- **Files modified:** 10 source, test, and verifier files; 3 ordered patch exports

## Accomplishments

- Added separate compileable target, connected, recent, audit, snapshot, ordinary-operation, and create-result DTOs; only the create-result type has `formatted_code`.
- Registered strict one-integer select/create/replace/cancel-presentation messages with a 32-row bound and no renderer-supplied Browser, profile, tab, document, stream, or authority identity.
- Bound the native adapter to the exact normal Browser that owns the Control Panel WebContents and excluded Control Panel, privileged, cross-window, and Private targets.
- Rebuilt weak ordinal rows for each snapshot generation, preserved the same selected live target, refused silent replacement after loss, and revalidated handle/list/Browser/profile/URL eligibility on every action.
- Published bounded sanitized target, viewer/controller, connected, recent, and newest-first audit display data with controller-first connected ordering and no raw content or authority fields.
- Changed duplicate create from implicit replacement to a non-mutating `REPLACEMENT_REQUIRED` result and added explicit old-digest-first replacement.
- Delivered ambiguity-safe eight-character codes only as `XXXX-XXXX` through `prometheusControlReceivePairingCreateResult`, retained only salted digest/expiry in the service, and zero-filled the unformatted native buffer after formatting.
- Added exact-window, stale ordinal, privileged target, cross-window, malformed message, five-minute TTL, replacement ordering, cancellation, structural privacy, and one-shot browser/service regressions.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Freeze sanitized snapshot types, strict messages, and sole code channel** — nested `6be8e7512e`, root `efc04eec8`, patch `0051`
2. **Task 2 (GREEN): Bind exact-window sanitized snapshots and ordinal revalidation** — nested `f0c5ed4e3b`, root `5534482db`, patch `0052`
3. **Task 3 (GREEN): Deliver one-use pairing code and close replacement/privacy races** — nested `ab3c5fe80a`, root `279851703`, patch `0053`

## Files Created/Modified

- `prometheus_side_panel_runtime.h/.cc` — Closed Control Panel supervision DTOs, bounded caps, serializers, strict operation type, and sole code-capable direct result.
- `prometheus_web_ui.h/.cc` — Four strict ordinal messages, invalid-input rejection, ordinary operation delivery, and dedicated one-shot create callback.
- `prometheus_browser_main_extra_parts.cc` — Exact-Browser target map, fresh sanitized snapshot projection, weak ordinal revalidation, service observation, create/replace/cancel adapter, formatting, and raw-buffer clearing.
- `prometheus_supervision_profile_service.h/.cc` — Public exact-target eligibility seam plus replacement-required create and explicit old-digest-first replacement.
- `prometheus_supervision_profile_service_unittest.cc` — Duplicate-create preservation and explicit replacement-order regression.
- `prometheus_web_ui_browsertest.cc` — Compile-time channel separation, recursive privacy, strict-message, exact-window, stale-reuse, TTL, replacement, cancellation, and one-shot coverage.
- `.planning/chromium/verify-phase-21.sh` — Static DTO/message/adapter/service privacy guards for focused browser and unit verification.
- `patches/0051` through `0053` — Stable ordered nested Chromium patch exports.

## Decisions Made

- Snapshot fields are represented by closed C++ DTOs before conversion to `base::Value`; regular delivery cannot acquire a code field through ad hoc dictionary mutation.
- The Control Panel target selector receives local ordinals only. Native code retains weak tabs and handles for one snapshot generation and rejects stale ordinals even if a new tab later occupies the same list position.
- Initial selection uses the latest eligible page in the exact window. Once initialized, target loss yields no selection until the user chooses from a fresh row set.
- An existing pending code is not disturbed by ordinary create. Only explicit replace erases it, records cancellation metadata, and proceeds to new generation.
- The service continues storing only salt, digest, timestamps, and exact native target authority. The raw code is returned once, formatted in the native adapter, and cleared from the unformatted buffer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made RED predicates assertion-safe**

- **Found during:** Task 1 RED verification
- **Issue:** Two browser-test predicates used a top-level JavaScript `return`, which Chromium rejected as a syntax error and classified as a crash instead of the required ordinary assertion failure.
- **Fix:** Wrapped each predicate in an immediately invoked function and reran the exact expected-failure gate.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** Two named RED tests were discovered and failed only through intended GTest assertions with status 1 and no fatal/crash markers.
- **Committed in:** `6be8e7512e`

**2. [Rule 1 - Bug] Used distinct origins for cross-window privacy evidence**

- **Found during:** Task 2 GREEN verification
- **Issue:** The first test used different paths on the same embedded-server origin, but the production snapshot correctly exposes canonical origin only, making the cross-window absence assertion ambiguous.
- **Fix:** Moved the other-window target to `other.test` while retaining the exact same browser isolation flow.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** The target regression passed for exact-window enumeration, privileged exclusion, cross-window exclusion, and old-ordinal rejection after close/replacement.
- **Committed in:** `f0c5ed4e3b`

**3. [Rule 2 - Missing Critical] Updated the existing pairing service regression**

- **Found during:** Task 3 service compatibility review
- **Issue:** The plan changed implicit replacement semantics but omitted the existing service unit-test file from its modification list.
- **Fix:** Updated the replacement test to require duplicate-create conflict, prove the old digest remains live, then call explicit replacement and prove the old digest is invalid before the new code is redeemable.
- **Files modified:** `prometheus_supervision_profile_service_unittest.cc`
- **Verification:** All six focused `PrometheusSupervisionProfileServiceTest.Pairing*` tests passed.
- **Committed in:** `ab3c5fe80a`

---

**Total deviations:** 3 auto-fixed (2 test bugs, 1 missing critical regression update).
**Impact on plan:** All fixes made the planned RED/GREEN and replacement evidence deterministic without widening renderer authority or product scope.

## Issues Encountered

- Task 1 initially exposed one missing DTO forward declaration and one missing direct test include during exact-object compilation; both were corrected before the RED evidence run.
- A verifier-local variable was first declared in the neighboring side-panel guard rather than the new Control Panel guard; scope was corrected before Task 2 compilation.
- The repository does not contain a standalone `clang-format` binary at the expected LLVM path, so formatting remained constrained to the existing Chromium style and `git diff --check`.

## Test Evidence

- Task 1 RED selected exactly 2 snapshot/create contract browser tests and failed only their intended unimplemented assertions.
- Task 2 GREEN selected 2 snapshot/target browser tests and passed exact-window target enumeration, safe display state, privileged/cross-window exclusion, and stale ordinal reuse rejection.
- Task 3 selected 2 create browser tests and passed strict argument handling, `XXXX-XXXX` formatting, five-minute expiry, one pending digest, replacement-required behavior, old-digest-first replacement, snapshot exclusion, and cancellation.
- The focused service gate selected all 6 `PrometheusSupervisionProfileServiceTest.Pairing*` tests and passed one-use, expiry, bounds, exact-target, privacy, and explicit replacement semantics.
- Final combined verification selected all 4 `PrometheusWebUIBrowserTest.SupervisionRuntime*` tests and passed, followed by clean root and nested `git diff --check`.
- Reviewed hashes stayed byte-identical: `.ninja_log` `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`, `.ninja_deps` `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`, Blink dylib `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`, Blink TOC `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`, and framework `resources.pak` `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`.
- Patches `0051`, `0052`, and `0053` have stable patch IDs `b9d72735327fff35aed07dea517ac6844916b692`, `334dc94cd741393a6027c99658b8d8a62f76ed46`, and `850d05a0fb87e8522a2ce4b859894f33a348a7c1`; each matches its nested commit.
- Applying `0051–0053` in order to nested base `344499e3f7` produced tree `40c8c13557ba55c088893a46863c0df784b4005c`, exactly matching nested commit `ab3c5fe80a`.

## User Setup Required

None. No credentials, packages, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-21 can add lifecycle observation, presentation erasure, viewer/controller actions, and teardown handling on the closed exact-window snapshot and direct one-shot result without changing the renderer identity boundary.

SUP-01, SUP-03, SUP-04, and SUP-05 remain phase-level in progress until Control Panel lifecycle/UI, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `6be8e7512e`, `f0c5ed4e3b`, and `ab3c5fe80a`
- FOUND: root task commits `efc04eec8`, `5534482db`, and `279851703`
- FOUND: ordered patches `0051`, `0052`, and `0053`
- VERIFIED: 2-test RED, 2-test Task 2 GREEN, 2-test create GREEN, 6-test service pairing gate, and final 4-test runtime suite
- VERIFIED: strict messages, exact-window isolation, stale ordinal rejection, one-shot code channel, replacement ordering, structural privacy, patch identity/replay, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
