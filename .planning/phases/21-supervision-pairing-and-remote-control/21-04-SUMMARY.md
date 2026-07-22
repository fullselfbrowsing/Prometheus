---
phase: 21-supervision-pairing-and-remote-control
plan: 04
subsystem: supervision-pairing-authority
tags: [chromium, cpp, supervision, pairing, authority, lifecycle, tdd]

requires:
  - phase: 21-01
    provides: Closed supervision states, browser-only authority types, checked generations, and hard resource limits
  - phase: 21-02
    provides: Dedicated bounded supervision transport contract and authority-free sanitized projection
  - phase: 21-03
    provides: Privacy-safe APC baseline, deterministic structural diff, and independent viewer cursor model
provides:
  - Agent-owned move-only observation leases over one registered PrometheusAgentTabData per exact tab
  - Digest-only one-use pairing with exact regular-profile Browser/tab binding, bounded attempts, and typed expiry
  - Independent view-only sessions with immutable redemption-owner capture and one atomic controller per tab
  - Exact-once owner-loss, target-loss, expiry, revoke, detach, Agent-shutdown, and supervision-shutdown convergence
affects: [21-05, 21-08, 21-09, 21-12, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Agent service remains the sole creator, registrar, owner, detach observer, and destroyer of tab authority data
    - Supervision observes ownership only through coalesced move-only leases whose opaque tokens fail closed after teardown
    - Viewer/controller authority is invalidated before sanitized notification and is never serialized, persisted, or reacquired

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Capture the current Agent owner exactly once at redemption, including empty, and terminalize on every later owner transition instead of adopting a replacement owner."
  - "Keep raw pairing codes only in the one-shot creation result; retain only a random salt and SHA-256 digest behind a global bounded attempt window."
  - "Drop the supervision lease only after terminal callbacks unwind; Agent invalidates tokens before tab-data destruction so late lease access and destruction are no-ops."

patterns-established:
  - "Successful tab-owner mutations synchronously publish coherent old/new owner values; failed and same-owner mutations publish nothing."
  - "Pending pairings and redeemed viewers share one exact-tab observation, while viewers expire and revoke independently and the last viewer triggers deferred release."
  - "Sanitized snapshots and newest-first bounded audit carry safe labels, origins, counts, times, and states only—never raw code, session, owner ID, lease, profile, or document authority."

requirements-completed: []
requirements-progressed: [SUP-03, SUP-04, SUP-05]

duration: 42min
completed: 2026-07-21
---

# Phase 21 Plan 04: Pairing, Viewer, Controller, and Agent Observation Summary

**Regular-profile supervision now pairs one exact tab through digest-only one-use credentials, captures immutable Agent ownership at redemption, supports independent viewers and one controller, and converges every authority-loss path through Agent-owned observation leases.**

## Performance

- **Duration:** 42 min
- **Started:** 2026-07-21T23:52:53Z
- **Completed:** 2026-07-22T00:34:14Z
- **Tasks:** 3
- **Files modified:** 14 including exported patches and this summary

## Accomplishments

- Added checked owner-transition and destruction notifications to `PrometheusAgentTabData`, with `PrometheusAgentService` retaining sole creation, registration, detach, ownership, invalidation, and destruction authority.
- Added coalesced move-only observation leases that resolve tab data only through live opaque Agent tokens, remove observers through Agent service, defer zero-lease pruning until callbacks unwind, and become harmless after detach or shutdown.
- Implemented regular-profile pairing with exact Browser/profile/tab binding, one-shot raw-code return, salted digest retention, replacement-before-create, five-minute expiry, bounded global attempts, atomic one-use redemption, and no active-tab fallback.
- Implemented independent view-only sessions, immutable current-owner capture at redemption, nonempty exact-owner control checks, one controller per tab, and conflict handling that cannot steal authority.
- Unified expiry, revoke, owner change, session release, target loss, tab-data destruction, Agent shutdown, and supervision shutdown through generation/controller invalidation before sanitized notification.
- Kept snapshots and newest-first bounded audit structurally free of raw pairing codes, dashboard sessions, owner IDs, leases, profiles, documents, selectors, and page content.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify one-use pairing and viewer/controller lifecycle** - nested `db56a37f2d`; patch tracking `5b335b6cd`
2. **Task 2 (GREEN): Implement pairing, redemption, viewers, and sole controller** - nested `73ac1e53cc`; patch tracking `f43b54f12`
3. **Task 3 (GREEN): Converge expiry, revoke, owner loss, target loss, and shutdown** - nested `5cc77dcfe3`; patch tracking `916205f24`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h` - Regular-profile pairing, viewer, controller, sanitized observer, and testing contract.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc` - Exact-target digest pairing, immutable owner capture, bounded state/audit, and idempotent terminal convergence.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc` - Eighteen pairing, owner, viewer, controller, privacy, target-loss, and cross-service teardown fixtures.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h` / `.cc` - Checked coherent owner-change and pre-destruction observer seam.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h` / `.cc` - Move-only observation lease registry, coalescing, token-first invalidation, and deferred unowned pruning.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc` - Five real `MockTabInterface` lease/ownership/detach/shutdown fixtures.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Supervision profile service and test registration.
- `.planning/chromium/verify-phase-21.sh` - Exact direct compilation and focused link coverage for Agent observation and supervision profile objects.
- `patches/0008-test-21-04-specify-supervision-pairing-lifecycle.patch` - Exact exported RED contract commit.
- `patches/0009-feat-21-04-implement-supervision-pairing-and-control.patch` - Exact exported pairing/viewer/controller GREEN commit.
- `patches/0010-feat-21-04-converge-supervision-lifecycle-teardown.patch` - Exact exported terminal-convergence GREEN commit.

## Decisions Made

- Agent service owns the only `PrometheusAgentTabData` unique pointer and detach subscription. Supervision receives a narrow move-only lease and never calls `GetOrCreateForTab`, registers detach callbacks, claims Agent authority, or destroys tab data.
- Pairing creation does not capture owner authority. Redemption consumes the matching code, revalidates the same Browser/profile/tab, obtains the Agent-owned observation, and commits the current owner value and viewer atomically.
- An empty redemption owner permits view-only observation but can never control. Any later successful owner transition—including empty to nonempty—terminalizes the old viewer before a sanitized snapshot is published.
- Same observer/tab requests coalesce to one Agent token with an internal lease count. The final release removes the observer through Agent service and posts a weak zero-owner prune rather than erasing inside an owner callback.
- Terminal sessions retain only bounded sanitized recent metadata and an in-memory generation lookup. Audit is globally bounded, newest-first in snapshots, and authority-free.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended the Phase 21 direct verifier for new production and test objects**

- **Found during:** Task 1 RED gate
- **Issue:** The plan added Agent observation and supervision service objects that were not present in the reviewed Ninja response, so the existing focused verifier could not compile or select the retained suite without explicit same-target synthesis.
- **Fix:** Added exact Agent object compilation plus same-target supervision profile production/test synthesis and focused-link inclusion while preserving `.ninja_log` and `.ninja_deps` byte-for-byte.
- **Files modified:** `.planning/chromium/verify-phase-21.sh`
- **Verification:** Fourteen RED tests selected and failed only by ordinary GTest assertions; eighteen final tests selected and passed with both metadata hashes unchanged.
- **Committed in:** `5b335b6cd` (Task 1 patch tracking commit)

---

**Total deviations:** 1 auto-fixed blocking verification issue.
**Impact on plan:** The verifier change was required to execute the plan's specified retained RED/GREEN gates and did not broaden product behavior.

## Issues Encountered

- The first direct RED compile exposed an unused skeleton token field, one GTest comma-macro expression, and a heterogeneous initializer list. Each contract-only compile issue was corrected before retaining the RED commit; the accepted RED run compiled every object and failed only through intended assertions.

## Verification

- RED gate - all 14 initial service fixtures compiled and were selected non-empty; the process exited only through intended GTest assertion failures.
- Task 2 lifecycle gate - all 11 `Pairing*`, `Viewer*`, and `Controller*` fixtures passed.
- Agent ownership gate - all 5 `PrometheusAgentServiceObservationTest.*` fixtures passed for fresh unowned creation, owner transitions, coalescing, deferred last release, detach, and shutdown.
- Final lifecycle gate - all 18 `PrometheusSupervisionProfileServiceTest.*` fixtures passed, including pending-only target loss, shared last-viewer release, Agent-shutdown-first, repeated terminal events, and bounded newest-first audit.
- Authority/privacy guard - supervision production code contains no `GetOrCreateForTab` or `ClaimIfUnowned`; serialized snapshot tests reject raw code, session, owner ID, lease, profile, document, selector, and page-content sentinels.
- Metadata preservation - `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` before and after focused verification.
- Patch identity - patches 0008, 0009, and 0010 have stable IDs `4bbd80ea074c3bf4f617dafab062841a28b7762b`, `97def075807c39620b9024d76a64ed26847716e3`, and `b02c6e6ecb323f0fe304a98477fb643cab1c8c27`, exactly matching their nested commits.
- Root and nested `git diff --check` - passed; both repositories were clean before summary creation.

Human UAT was not run and is not claimed; this plan establishes browser-process lifecycle authority with automated acceptance.

## User Setup Required

None. No credentials, external services, or configuration are required.

## Next Phase Readiness

Plan 21-05 can bind this regular-profile lifecycle service to the exact profile's Agent keyed service and browser teardown ordering without adding another tab-data owner or authority serializer.

No blockers or threat flags remain. SUP-03, SUP-04, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: all nine planned Chromium source/build artifacts plus verifier wiring
- FOUND: nested RED/GREEN commits `db56a37f2d`, `73ac1e53cc`, and `5cc77dcfe3`
- FOUND: matching non-empty exported patches `0008`, `0009`, and `0010` with exact stable identities
- VERIFIED: 14-test RED, 11-test Task 2 GREEN, 5 Agent observation tests, and 18-test final lifecycle GREEN; exact metadata hashes unchanged and authority/privacy searches clean
- VERIFIED: root and nested repositories clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-21*
