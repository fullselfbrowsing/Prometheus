---
phase: 21-supervision-pairing-and-remote-control
plan: 08
subsystem: browser-supervision-dashboard
tags: [chromium, browser, dashboard, capture-hub, long-poll, fanout, lifecycle, privacy, tdd]

requires:
  - phase: 21-07
    provides: Sole exact-document renderer/APC capture hub with bounded independent consumers
provides:
  - Exact-target profile-service hub registry and opaque dashboard-consumer attachment
  - Browser-only dashboard baseline, diff, ack, resync, long-poll, cancellation, and lifecycle delegation
  - Independent two-viewer real mutation, navigation, expiry, revoke, owner-loss, target-loss, and final-release proof
affects: [21-09, 21-10, 21-11, 21-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Profile service retains pairing and immutable-owner authority while dashboard delivery stores only an opaque capture-consumer token
    - Hub readiness callbacks signal data, resync, or consumer end while the service retains the one bounded dashboard completion callback
    - Opaque wait generations make cancellation authoritative even after a hub readiness signal has been posted

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Redeem attaches to the one exact-target hub before consuming the pairing; each live dashboard record retains only its opaque hub token plus service-owned authority."
  - "Long-poll ownership is split deliberately: the hub owns one readiness signal per consumer, while the profile service owns the dashboard callback and an opaque cancellation generation."
  - "A queued readiness signal cannot defeat cancellation, shutdown, or teardown because service token mismatch makes every late signal a no-op."
  - "Target loss terminalizes all viewers on that exact target coherently, but expiry, revoke, end, lag, ack, and cancellation remain consumer-local."

patterns-established:
  - "Dashboard baseline/diff/ack calls always revalidate exact target and immutable redemption owner before resolving the opaque hub token."
  - "One consumer's ack, wait, cancel, lag, resync, expiry, revoke, or end cannot advance or terminate another consumer."
  - "The final dashboard detach releases the sole hub exactly once; no profile-service object owns renderer Mojo, APC trees, history, or cursors."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-03]

duration: 1h18min
completed: 2026-07-22
---

# Phase 21 Plan 08: Independent Dashboard Capture Consumers Summary

**Separately redeemed dashboard viewers now consume one exact-target browser capture hub through opaque tokens, with independent baseline/diff/ack/wait/resync/lifecycle state and real renderer fanout proven without duplicating capture authority.**

## Performance

- **Duration:** 1h18min
- **Started:** 2026-07-22T06:22:59Z
- **Completed:** 2026-07-22T07:41:00Z
- **Tasks:** 3 plus one closeout correctness fix
- **Files modified:** 17 including exported patches, planning state, and this summary

## Accomplishments

- Added a profile-service registry that creates exactly one capture hub for an exact `BrowserWindowInterface`/tab target and reuses it for every redeemed dashboard viewer on that target.
- Made redemption attach a `kDashboard` consumer before consuming the pairing, then retain only the opaque `CaptureConsumerToken`; pairing digest, immutable owner, controller eligibility, label, expiry, and audit remain service-owned.
- Routed dashboard baseline, diff, and ack operations through the stored token after exact-target and immutable-owner revalidation. Tree, epoch, retained history, offered cursor, ack cursor, lag, and resync state remain exclusively in the hub.
- Added one bounded long-poll per dashboard consumer. Hub callbacks report only data-ready, baseline-required, or consumer-ended; the service owns the user completion callback and opaque wait token so cancellation wins over queued readiness.
- Converged revoke, end, expiry, owner loss, target loss, shutdown, resync, and final detach without duplicate callback completion or cross-consumer cursor/liveness changes.
- Extended the real browser fixture through profile-service pairing/redeem/read/ack APIs. Two dashboard sessions receive identical safe diffs from each server-authored DOM mutation while instrumentation reports one renderer binding and one APC capture per epoch.
- Proved asymmetric ack, independent revoke and expiry, navigation baseline replacement, one final disable, password/payment/OTP omission, and absence of raw mutation records.
- Strengthened the verifier to require the wait/cancel surface and lifecycle tests while retaining renderer-ownership, privacy, exact-source, direct-compile, patch-integrity, and immutable-build-artifact gates.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify one hub registry and independent redeemed viewers** - nested `531fa602c2`; patch tracking `557222ed5`
2. **Task 2 (GREEN): Delegate dashboard baseline/diff/ack and lifecycle to hub consumers** - nested `c56fa48e79`; patch tracking `a65d06759`
3. **Task 3 (GREEN): Prove simultaneous real dashboard consumers stay live** - nested `6b2871dcd2`; patch tracking `b14936138`
4. **Closeout fix: Bound independent dashboard diff waits and cancellation** - nested `6c35bb23f1`; patch tracking `2b17386b3`

## Files Created/Modified

- `prometheus_supervision_profile_service.h` / `.cc` - Exact-target hub registry, opaque viewer attachment, safe delivery delegation, bounded wait/cancel API, and coherent lifecycle teardown.
- `prometheus_supervision_profile_service_unittest.cc` - Hub reuse, delegation, independent ack/lag/resync/wait/cancel/expiry/revoke, owner/target loss, shutdown, and final-release coverage.
- `prometheus_supervision_capture_hub.h` / `.cc` - One-wait-per-consumer readiness signaling with asynchronous, exactly-once data/resync/end completion.
- `prometheus_supervision_capture_hub_unittest.cc` - Consumer-local long-poll data, cancellation, resync, revoke, and expiry coverage.
- `prometheus_supervision_capture_hub_browsertest.cc` - Two separately redeemed dashboard viewers over real server-authored mutation and navigation paths.
- Browser and Views `BUILD.gn` files - Production service-to-hub and real browser-test dependency registration.
- `.planning/chromium/verify-phase-21.sh` - Dashboard delegation/long-poll guards and exact direct native/browser verification.
- `patches/0019-test-21-08-specify-shared-dashboard-capture-consumer.patch` - Exact exported RED contract commit.
- `patches/0020-feat-21-08-attach-dashboard-viewers-to-shared-captur.patch` - Exact exported dashboard attachment GREEN commit.
- `patches/0021-test-21-08-prove-real-dashboard-capture-fanout.patch` - Exact exported real-browser GREEN commit.
- `patches/0022-fix-21-08-bound-dashboard-diff-waits.patch` - Exact exported long-poll correctness fix.

## Decisions Made

- The profile service is the only dashboard authority owner. The hub accepts only browser-created consumer tokens and expiries, and returns only safe stamped deliveries or content-free readiness reasons.
- A pairing is consumed only after exact-target hub creation and consumer attachment succeed, preventing a valid one-time code from being lost to a partial delivery setup.
- The service retains the dashboard callback because it alone can translate hub readiness into session-scoped errors and lifecycle transitions. The hub retains only one content-free readiness callback per consumer.
- Readiness is posted asynchronously to prevent reentrant hub destruction. Cancellation clears the service wait generation even if the hub already posted a signal, so the late callback cannot reach the user.
- Exact target or immutable owner loss terminalizes all viewers attached to that target before dispatch. Ordinary consumer events remain independent and release the hub only after its final consumer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing production and browser-test hub dependencies**

- **Found during:** Task 2 direct compile and Task 3 browser linkage
- **Issue:** The planned service/browser sources used the capture hub but their GN targets did not yet depend on the hub production target or profile-service target.
- **Fix:** Added the exact service-to-hub and Views browser-test dependencies without broadening component ownership.
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`, `chrome/browser/ui/views/prometheus/BUILD.gn`
- **Verification:** Exact synthesized service and browser-test compilation/linkage pass.
- **Committed in:** `c56fa48e79` / `a65d06759` and `6b2871dcd2` / `b14936138`

**2. [Rule 1 - Bug] Detached consumers even after the exact Browser weak pointer died**

- **Found during:** Task 2 target-loss lifecycle tests
- **Issue:** Dispatch correctly required a live exact Browser, but cleanup reused that requirement and could therefore leave the hub consumer attached after target destruction.
- **Fix:** Kept dispatch fail-closed while allowing internal detach through the already-validated tab/hub registry entry; one viewer detecting target loss terminalizes every same-target viewer coherently.
- **Files modified:** `prometheus_supervision_profile_service.cc`, `prometheus_supervision_profile_service_unittest.cc`
- **Verification:** Owner/target-loss tests end all viewers, destroy the final hub, and increment disable exactly once per released hub.
- **Committed in:** `c56fa48e79` / `a65d06759`

**3. [Rule 2 - Missing Critical] Implemented the planned independent long-poll contract**

- **Found during:** Final Plan 08 acceptance audit
- **Issue:** Nonblocking baseline/diff/ack delegation passed, but the explicit requirement that Viewer A long-poll cannot affect Viewer B had no concrete bounded wait/cancel API.
- **Fix:** Added one readiness callback per hub consumer and one opaque wait token/user callback per service viewer, including queued-signal cancellation, resync, revoke, expiry, shutdown, owner-loss, target-loss, and exactly-once completion semantics.
- **Files modified:** Capture-hub and profile-service headers, sources, tests, and `.planning/chromium/verify-phase-21.sh`
- **Verification:** All 5 focused long-poll tests, 45 combined hub/service native tests, and both real dashboard browser tests pass.
- **Committed in:** `6c35bb23f1` / `2b17386b3`

---

**Total deviations:** 3 auto-fixed issues (1 blocking dependency issue, 1 lifecycle bug, 1 missing critical contract).
**Impact on plan:** Every fix was required for the planned exact-target, independent-consumer, and bounded-callback guarantees. No renderer authority, alternate capture path, or new external transport was introduced.

## Issues Encountered

- Chromium intentionally rejects stateful lambdas passed directly to `base::BindOnce`; the new test callbacks were switched to `base::BindLambdaForTesting`, after which the focused compile and all suites passed.
- The final acceptance audit was intentionally run after the original three commits and caught the absent long-poll surface. It was preserved as an ordered follow-up commit/patch instead of rewriting the already-exported RED/GREEN history.

## Test Evidence

- Task 1 RED gate - 3 selected dashboard attachment tests reached only their intentional GTest contract failures; architecture and metadata guards stayed green.
- Task 2 GREEN gate - all 9 selected hub/profile-service dashboard tests passed through exact direct compile/link verification.
- Original Plan 08 native gate - all 18 selected hub/profile-service fixtures passed; the broader pre-long-poll hub/service regression passed 40/40.
- Focused long-poll gate - all 5 new hub/service wait tests passed across data, cancel, resync, revoke, expiry, shutdown, owner loss, and target loss.
- Final combined native gate - all 45 `PrometheusSupervisionProfileServiceTest.*` and `PrometheusSupervisionCaptureHubTest.*` fixtures passed together.
- Final real-browser gate - both `TwoDashboardConsumers*` fixtures passed through actual pairing/redeem/read/ack APIs, renderer dirty signaling, APC recapture, independent navigation baselines, and final release.
- Ownership audit - capture hub source contains exactly one `document_remote_->Enable` call; the profile service contains zero Mojo endpoint, APC tree, retained-history, acknowledged-cursor, or next-sequence ownership terms.
- Privacy audit - real baseline and diff omit password, payment, and OTP sentinels plus raw mutation-record fields while retaining the two visible server-authored markers.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Reviewed Blink artifacts remained immutable - dylib hash `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; TOC hash `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patch identity - patches 0019, 0020, 0021, and 0022 have stable IDs `349b48404e14fd223994c12a4221381dea90a622`, `3f005ae71107a044a108d05e7f67e5c3f8b63226`, `5d00a5efb676e436337371f5463042ce660f75bd`, and `6e2d6cf736761407e8239686096b55dd44872187`, exactly matching their nested commits.
- Patch ancestry - nested commits are ordered `531fa602c2` -> `c56fa48e79` -> `6b2871dcd2` -> `6c35bb23f1`, with the final fix parent exactly `6b2871dcd2`.
- Root and nested `git diff --check` passed, and both implementation repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan establishes a browser/service delivery primitive whose acceptance is fully automated.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-09 can bind the authenticated loopback gateway to this profile-owned dashboard surface. Its dispatcher can initiate and cancel bounded waits using opaque service tokens without receiving a renderer endpoint, hub consumer token, capture tree, cursor, or authority identifier.

No blockers or threat flags remain. SUP-01, SUP-02, and SUP-03 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: exact-target service registry, opaque dashboard consumer attachment, safe baseline/diff/ack delegation, and bounded wait/cancel APIs
- FOUND: nested commits `531fa602c2`, `c56fa48e79`, `6b2871dcd2`, and `6c35bb23f1`
- FOUND: matching non-empty exported patches 0019 through 0022 with exact stable identities and ordered ancestry
- VERIFIED: 3-test RED, 9-test Task 2 GREEN, 5-test focused long-poll, 45-test combined native, and 2-test real-browser gates
- VERIFIED: one renderer Enable owner, zero service-side Mojo/tree/history/cursor duplication, privacy omissions, and byte-identical reviewed build artifacts
- VERIFIED: root and nested implementation repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
