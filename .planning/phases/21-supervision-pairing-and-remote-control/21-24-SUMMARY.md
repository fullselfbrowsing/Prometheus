---
phase: 21-supervision-pairing-and-remote-control
plan: 24
subsystem: chromium-supervision-test-composition
tags: [chromium, supervision, gateway, composition, exact-binding, teardown, tdd]

requires:
  - phase: 21-23
    provides: Production-inert conditional gateway handoff and validated two-slot bootstrap
provides:
  - Sole browser-composition binding from the abstract handoff dispatcher to the regular-profile supervision service
  - Exact gateway-session Profile, Browser, stable-tab, origin, document, and Agent-owner re-resolution
  - Production redemption observation for the exact service/profile/tab authority
  - Early test-dispatcher unbind and bootstrap zeroization before production teardown
affects: [21-25, 21-26, built-app-supervision-smoke]

tech-stack:
  added: []
  patterns:
    - Lazy first-request pinning to a gateway-owned exact session binding
    - Weak composition callbacks with request-scoped concrete target objects
    - Dispatcher unbind restoring 404 before bootstrap destruction

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Install the test dispatcher only after the real gateway starts and only when one disposable regular profile and its supervision service survive the complete bootstrap gate."
  - "Expose the gateway's already-stored exact session binding through a dependency-neutral accessor; all concrete Profile/tab/document/service validation remains in browser composition."
  - "Create codes only through the normal exact-browser `PrometheusSupervisionProfileService::CreatePairing` primitive and wipe its transient raw result before returning the formatted one-shot value."
  - "Observe successful production redemption only when service, profile identity, and stable tab match the pinned handoff authority."
  - "Clear redemption observation, unbind the test dispatcher, and destroy/zeroize bootstrap state before dashboard dispatch, Agent compatibility dispatch, and gateway teardown."

patterns-established:
  - "Launch classification may locate the sole disposable test profile once; request handling never selects an active profile, Browser, tab, or global fallback."
  - "The absent, invalid, OTR, persistent-profile, missing-service, and official-build paths allocate no bootstrap owner and leave the contract route at 404."
  - "Dialog responses remain validated bootstrap state but are not installed or consumed by production composition until Plan 21-25."

requirements-completed: [SUP-03, SUP-04, SUP-05]

duration: 50min
completed: 2026-07-24
---

# Phase 21 Plan 24: Browser Composition Handoff Summary

**The test-only supervision handoff is now bound solely at browser composition, re-resolves the gateway's exact live target for every operation, uses the normal pairing primitive, and returns to 404 before any production dispatcher or gateway teardown.**

## Performance

- **Duration:** 50min
- **Started:** 2026-07-25T00:47:00Z
- **Completed:** 2026-07-25T01:38:00Z
- **Tasks:** 2
- **Files modified:** 7 nested source/test files, 1 nested build file from RED, 1 root verifier, and 2 ordered patch exports

## Accomplishments

- Added a retained RED contract for valid composition bind, all non-bind launch classes, exact-target mismatch denial, idempotent unbind, 404 restoration, and teardown ordering.
- Made bootstrap binding lazy so the browser-issued gateway session can be created after process startup while still pinning the first exact request to the validated profile and configured loopback origin.
- Added a dependency-neutral gateway accessor for only the already-stored exact session Profile, Browser, and stable tab; the gateway gained no concrete supervision service, renderer, or bootstrap dependency.
- Re-resolved the exact normal Browser, stable tab, current live primary document, canonical HTTP(S) origin, nonempty Agent owner, and regular-profile supervision service for every handoff and immediately before code creation.
- Routed code creation through the normal exact-target `CreatePairing` method, enforced returned stable-tab and eight-character code shape, and wiped transient raw code buffers.
- Connected successful production redemption back to the two-slot bootstrap only for the exact supervision service, profile identity, and stable tab.
- Made unbind idempotent and ordered: clear redemption observation, disable the gateway test route, invalidate pending weak callbacks, zeroize/destroy bootstrap state, then clear dashboard and Agent dispatchers and shut down the gateway.
- Strengthened the verifier with exact-session, no-active/global-fallback, normal-pairing, source-layer, and early-unbind order guards.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the ordered root patch chain:

1. **Task 1 (RED): Specify the sole concrete bind, non-bind, and shutdown order** — nested `434463300b`, root `85ac83ebb`, patch `0063`
2. **Task 2 (GREEN): Bind exact profile authority and tear it down before production dispatchers** — nested `6f86487de6`, root `2436330ad`, patch `0064`

## Files Created/Modified

- `prometheus_browser_main_extra_parts.h/.cc` — Validated composition owner, exact session/target/service resolution, normal pairing creation, exact redemption observation, and ordered teardown.
- `prometheus_agent_gateway.h/.cc` — Dependency-neutral accessor for the gateway's existing exact session binding.
- `prometheus_supervision_test_bootstrap.h/.cc` — Lazy exact binding, exact profile/tab redemption checks, and terminal expected-origin clearing.
- `prometheus_supervision_test_bootstrap_unittest.cc` — Composition bind/non-bind, exact mismatch, redemption order, 404 restoration, idempotent teardown, and lazy-state zeroization coverage.
- `BUILD.gn` — Direct composition/bootstrap and unit-test dependencies required by the RED contract.
- `verify-phase-21.sh` — Fresh synthesized bootstrap object compilation plus exact bridge, no-fallback, and teardown-order guards.
- `patches/0063` and `0064` — Stable ordered nested Chromium patch exports.

## Decisions Made

- A gateway request is authoritative only for its existing session binding. The composition accepts no active-window, active-tab, last-used-profile, or global-service substitute.
- The startup scan is limited to classifying one disposable regular runtime-test profile after the gateway reports ready. It is never used to resolve a handoff request.
- The bootstrap stores no concrete Chromium pointers. Opaque identities and weak/request-scoped objects keep teardown and target loss fail-closed.
- Production remains inert: ordinary launches, official builds, invalid bootstrap files/types, persistent or OTR profiles, ambiguous/missing profiles, and missing services never install the optional handoff dispatcher.
- Dialog-response automation remains intentionally unused in this plan; Plan 21-25 owns the separate after-widget seam.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Exposed the gateway's exact stored session binding**

- **Found during:** Task 2 exact composition implementation
- **Issue:** The frontmatter file list did not include gateway source files, but the dependency-neutral handoff DTO intentionally carries no Profile/Browser pointers. Browser composition could not re-resolve the gateway-selected exact session without either a gateway accessor or a forbidden active/global fallback.
- **Fix:** Added `GetExactSessionBindingForComposition`, returning only weak Profile/Browser pointers and the stored stable tab for the named live session. Concrete supervision service and document logic remain absent from the gateway.
- **Files modified:** `prometheus_agent_gateway.h`, `prometheus_agent_gateway.cc`
- **Verification:** Gateway source-layer guards pass; strict exact-session/no-fallback composition guards pass.
- **Committed in:** `6f86487de6`

**2. [Rule 1 - Bug] Compiled both sides of the new direct bootstrap link**

- **Found during:** Task 1 RED direct-link verifier
- **Issue:** Plan 23's bootstrap objects were not present in the fixed Siso query graph. The verifier synthesized the new test object but initially lacked the corresponding production object.
- **Fix:** Synthesized both production and unit-test bootstrap objects from same-target runtime-bootstrap compile templates and linked the production object explicitly.
- **Files modified:** `.planning/chromium/verify-phase-21.sh`
- **Verification:** RED, full 25-test GREEN, and post-hardening 4-test composition runs all compiled and linked from fresh objects without changing reviewed build metadata.
- **Committed in:** `85ac83ebb`

---

**Total deviations:** 2 auto-fixed issues.
**Impact on plan:** Both fixes were necessary to prove the planned exact composition boundary without weakening dependency layering or fixed-output verification.

## Issues Encountered

- The first GREEN run compiled and linked successfully but exposed test expectation drift: gateway JSON status values are uppercase, and a lazy bootstrap that expires or shuts down before its first request has no pinned session/document/owner buffers to clear. Assertions were corrected to match the existing contract and the stricter lazy lifetime.
- The first isolated patch replay attempt used a mistyped detached baseline and was rejected as invalid. The final strict temporary-index replay used the actual `0063` parent and compared the resulting tree exactly.

## Test Evidence

- Task 1 RED discovered 4 composition tests and failed only the 3 frozen missing-behavior assertions; the non-bind/404 case already passed.
- Final full verification discovered and passed all 25 `PrometheusSupervisionTestBootstrapTest.*` and `PrometheusRuntimeTestBootstrapTest.*` cases.
- Post-review `PrometheusSupervisionTestBootstrapTest.Composition*` verification passed all 4 cases.
- Root and nested `git diff --check` gates passed; both repositories were clean after task commits.
- `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Reviewed Blink dylib remained `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; its TOC remained `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patch SHA-256 values are `e9b0435b5fd2a35f92f79c15da65fda7eff38ba5a5c038c40af4d6213326d597` for `0063` and `0ebbe057b3449df29c33e35d4deb9236b60e136920e03f07a67a83a1ac8163b2` for `0064`; each is byte-identical to a fresh export of its nested commit.
- Applying `0063–0064` through an isolated temporary index at nested base `e4e518d3e1` produced exact tree `6e3fe7230b34032872b36bd4908648b0012a41e0`, matching nested Chromium HEAD.

## User Setup Required

None. The route remains unavailable unless Plan 21-25's controlled built-smoke launch supplies the already specified non-official runtime-test switches and owner-only bootstrap file.

## Next Phase Readiness

Plan 21-25 can exercise the real built app, install its separate after-widget dialog automation seam, and prove two-viewer/MCP supervision against this exact composition-owned handoff.

No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `434463300b` and `6f86487de6`
- FOUND: root task commits `85ac83ebb` and `2436330ad`
- FOUND: ordered patches `0063` and `0064`
- VERIFIED: intended 4-test RED, full 25-test GREEN, and post-hardening 4-test composition gate
- VERIFIED: ordinary/official/invalid/persistent/OTR/missing-service non-bind, exact service/profile/Browser/tab/origin/document/owner continuity, normal code creation, exact redemption order, early 404 restoration, zeroization, source layering, patch identity, and exact patch replay

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
