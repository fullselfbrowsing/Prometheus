---
phase: 21-supervision-pairing-and-remote-control
plan: 23
subsystem: chromium-supervision-test-handoff
tags: [chromium, supervision, gateway, bootstrap, loopback, zeroization, tdd]

requires:
  - phase: 21-22
    provides: Complete private Control Panel supervision lifecycle UI
  - phase: 21-20
    provides: Exact-window pairing creation and one-shot code presentation
provides:
  - Validated non-official disposable-profile supervision test bootstrap
  - Conditional authenticated loopback handoff route absent without an installed dispatcher
  - Exact-bound two-slot sequential pairing-code state machine
  - Constant-time challenge validation, bounded attempts/expiry, and instrumented secure cleanup
affects: [21-24, 21-25, 21-26, built-app-supervision-smoke]

tech-stack:
  added: []
  patterns:
    - Boolean route-recognition fact derived only from optional dispatcher installation
    - Dependency-neutral move-only handoff DTOs with secure destructors
    - Consume-before-return one-shot state with exact binding continuity

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_test_bootstrap_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Recognize the test route only when an abstract validated dispatcher is installed; keep all concrete bootstrap/profile composition out of the gateway."
  - "Require exact runtime-test switches, non-official disposable regular profile facts, a 0600 no-follow file, a closed schema, and a canonical loopback HTTP origin before creating state."
  - "Bind both slots to the initial profile/browser/stable-tab/origin/document/owner facts, require slot-one redemption before slot two, and consume a slot before code creation returns."
  - "Wipe request authority before callback reentrancy and funnel challenge, session, document, owner, and transient code cleanup through one idempotent terminal path."

patterns-established:
  - "Conditional closed path: perimeter validation precedes route recognition, and absent dispatcher state returns 404 before parsing or native dispatch."
  - "Test-only authority seam: gateway DTOs contain only challenge, browser-issued session, sequence, status, and one intentional delivered code."
  - "Terminal privacy: exact-once zeroization instrumentation covers success, denial, target loss, expiry, unbind, shutdown, exhaustion, and code-creation failure."

requirements-completed: [SUP-03, SUP-04, SUP-05]

duration: 50min
completed: 2026-07-24
---

# Phase 21 Plan 23: Conditional Supervision Test Handoff Summary

**A production-inert authenticated loopback route now delivers exactly two exact-target pairing codes only after a validated non-official runtime-test bootstrap, with complete perimeter preservation and instrumented secure cleanup.**

## Performance

- **Duration:** 50min
- **Started:** 2026-07-24T23:39:20Z
- **Completed:** 2026-07-25T00:29:08Z
- **Tasks:** 3
- **Files modified:** 9 nested source/test/build files; 3 ordered patch exports

## Accomplishments

- Added the exact `--prometheus-supervision-test-bootstrap=<absolute path>` boundary beside `--test-type=prometheus-runtime`, gated by non-official, disposable, regular, non-OTR profile facts.
- Validated an owner-only 0600 no-follow file with exact five-key JSON schema, 64-character lowercase-hex challenge, canonical loopback HTTP origin, two slots, and the closed dialog-response sequence.
- Added move-only dependency-neutral handoff request/result DTOs and an optional dispatcher without introducing a concrete bootstrap, profile-service, dialog, codec, catalog, health, diagnostics, WebUI, or MCP dependency.
- Kept `/v1/test/supervision-handoff` absent by default; installation changes only conditional path recognition after the existing peer, Host, Origin, bearer, method, JSON media, body, and inflight perimeter.
- Implemented exact profile/browser/stable-tab/origin/document/current-owner continuity, constant-time challenge checks, fixed attempts and TTL, sequential consume-before-return slots, slot-one redemption gating, and closed dialog responses.
- Added secure request/result ownership, transient pairing-code wiping, one idempotent terminal cleanup path, and exact-once instrumentation across all success and failure boundaries.
- Added 39-test final coverage for launch/file/schema/origin denials, route absence and install/unbind, validation order, full gateway regressions, output privacy, source layering, and terminal zeroization.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the ordered root patch chain:

1. **Task 1 (RED): Freeze the dispatcher-aware closed path and test-launch boundary** — nested `9056606bd7`, root `684f89928`, patch `0060`
2. **Task 2 (GREEN): Implement conditional gateway dispatch and sequential handoff state** — nested `becc362447`, root `9b7a21649`, patch `0061`
3. **Task 3 (GREEN): Lock zeroization, non-exposure, and production-path regressions** — nested `e4e518d3e1`, root `466a52559`, patch `0062`

## Files Created/Modified

- `prometheus_supervision_test_bootstrap.h/.cc` — Closed launch validator, file boundary, exact binding state, two-slot dispatcher, dialog sequence, TTL/attempt caps, and secure cleanup.
- `prometheus_supervision_test_bootstrap_unittest.cc` — Launch, schema, file, binding, ordering, replay, timeout, teardown, dialog, and exact-once zeroization coverage.
- `prometheus_agent_gateway_contract.h/.cc` — Conditional validator fact, move-only DTOs, strict duplicate-safe request parser, serializer, and dependency-neutral dispatcher.
- `prometheus_agent_gateway.h/.cc` — Optional dispatcher installation, atomic IO-thread recognition fact, absent-route 404, abstract dispatch, response serialization, and shutdown.
- `prometheus_agent_gateway_unittest.cc` — Contract-order, complete-perimeter, install/unbind, parser/privacy, recursive output, source-layer, and unchanged gateway regression coverage.
- `BUILD.gn` — Bootstrap source set plus unit-test source/dependency wiring.
- `patches/0060` through `0062` — Stable ordered nested Chromium patch exports.

## Decisions Made

- Validation sees only whether the optional dispatcher is installed. It never consults bootstrap state, profile services, a browser, or a tab, keeping route recognition dependency-neutral and fail-closed.
- The bootstrap receives a composition-owned exact-binding callback and exact-target code-creation callback. It never selects an active profile/tab or claims ownership.
- The route body is a closed three-key object. Duplicate keys, extras, malformed values, non-lowercase challenges, invalid sessions, and sequences outside one or two fail before dispatch without echo.
- Sequence two remains unavailable until sequence-one redemption is observed. Replays, out-of-order requests, owner/document/target changes, timeout, shutdown, and attempt exhaustion return no credential.
- Request challenge/session buffers are wiped before invoking completion callbacks so callback reentrancy cannot extend their lifetime.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Closed the unit-fixture observer lifetime before bootstrap destruction**

- **Found during:** Task 3 final 39-test gate
- **Issue:** Two otherwise-passing tests left a live bootstrap until reverse fixture-member destruction, allowing its destructor to call an unretained zeroization observer after the observer vector had been destroyed.
- **Fix:** Reset the bootstrap in fixture `TearDown()` while every observer dependency is still alive.
- **Files modified:** `prometheus_supervision_test_bootstrap_unittest.cc`
- **Verification:** The exact 39-test final filter passed with both former teardown crashes green.
- **Committed in:** `e4e518d3e1`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The fix preserves the planned ownership model and strengthens deterministic teardown without changing product scope.

## Issues Encountered

- The existing Phase 21 verifier predates Plan 23 object discovery: it compiled the new unit object but omitted the new bootstrap production object from its direct linker response. The already-compiled object was added once to the generated local `browser_tests.rsp`; no source, patch, Ninja metadata, or reviewed artifact changed. Plan 26 remains the owner of final verifier handoff guards/counts.
- The first GREEN compile used `GURL::path_piece()`, unavailable in this Chromium revision. Replacing it with the equivalent `GURL::path()` resolved the diagnostic.
- The first final run selected 39 tests and passed 37 before the fixture teardown issue above crashed two nonterminal cases. The lifetime fix made the full rerun green.

## Test Evidence

- Task 1 RED discovered 11 runnable tests and failed only intended new GTest assertions after all static guards passed.
- Task 2 GREEN discovered and passed 5 focused gateway/handoff tests.
- Task 3 final verification discovered and passed all 39 `PrometheusSupervisionTestBootstrapTest.*` and `PrometheusAgentGatewayTest.*` cases.
- Final root and nested `git diff --check` gates passed.
- `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Reviewed Blink dylib remained `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; its TOC remained `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- Patch SHA-256 values are `308ed6c8117aa5335635bd36136de6f5b69d09436bf2d3d97055e65c8780b437` for `0060`, `0e961de625412d7364ddecb8b9aa8e167e316090222a7bc42d86b7194727e5d0` for `0061`, and `f036398940758866d109df49486acebe04f1da88da78f40f0033ca0829495457` for `0062`; each is byte-identical to a fresh export of its nested commit.
- Applying `0060–0062` in order to nested base `34784fe9b8` produced exact tree `fceca7e99b68079c7d5e331932766a14eabeb0a9`, matching nested Chromium HEAD.

## User Setup Required

None. No credentials, packages, listeners, external services, or configuration are required.

## Next Phase Readiness

Plan 21-24 can install the abstract dispatcher at browser composition and bind it to the exact supervision profile/browser/tab service without changing the gateway contract or production supervision operation set.

No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `9056606bd7`, `becc362447`, and `e4e518d3e1`
- FOUND: root task commits `684f89928`, `9b7a21649`, and `466a52559`
- FOUND: ordered patches `0060`, `0061`, and `0062`
- VERIFIED: 11-test intended RED, 5-test focused GREEN, final 39-test complete gateway/bootstrap gate
- VERIFIED: exact launch/file/schema/origin gating, absent route, full perimeter, two-slot order, exact binding, no production codec/catalog route, recursive privacy, secure cleanup, patch identity, and exact patch replay

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
