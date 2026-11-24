---
phase: 21-supervision-pairing-and-remote-control
plan: 12
subsystem: shared-hub-agent-compatibility
tags: [chromium, supervision, agent, dashboard, capture-hub, gateway, tdd]

requires:
  - phase: 21-11
    provides: Exact-Browser Agent dispatch and the sole dual-path supervision composition root
provides:
  - Real five-command MCP compatibility semantics backed by an independent consumer of the exact dashboard capture hub
  - Authority-free baseline, diff, no-change, resync, and end results with serialization-before-ack cursor safety
  - Live mixed dashboard/Agent browser proof across real mutations, navigation, owner loss, target close, and independent teardown
  - Production dashboard and Agent gateway binding/unbind proof with one-shot pending completion
affects: [21-13, 21-14, phase-21-supervision, agent-gateway, browser-composition]

tech-stack:
  added: []
  patterns:
    - Compatibility sessions retain only a shared-hub consumer token, exact stable tab, generation, expiry, and pending callback state
    - Agent delivery advances the hub cursor only after the closed transport serializer accepts the projected result
    - Production composition teardown ends owned dashboard sessions before clearing Agent dispatch

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc

key-decisions:
  - "Attach MCP compatibility as kAgentCompatibility on GetOrCreateCaptureHub; never create a second renderer remote, APC capture owner, safe tree, history, or cursor implementation."
  - "Preflight every compatibility result through SerializeAgentTransportResult before acknowledging a hub delivery, leaving rejected batches readable for safe recovery."
  - "Return no_change only after a fresh validated hub read reports no available batch and the Agent consumer is settled."
  - "Exercise both production composition callbacks with a test-owned loopback gateway and perform dashboard cancellation/unbind before Agent unbind."

patterns-established:
  - "Start replaces only the calling Agent generation; Agent end, mismatch, expiry, session loss, target close, and shutdown detach only that token."
  - "Dashboard and Agent consumers observe one document epoch and one APC recapture while retaining independent ack, cursor, wait, and end state."
  - "Compatibility output contains safe typed APC topology only and cannot carry dashboard session, epoch, sequence, cursor, selector, URL, renderer, raw content, or secret authority."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-02, SUP-03, SUP-05]

duration: 1h51min
completed: 2026-07-22
---

# Phase 21 Plan 12: Shared-Hub Agent Compatibility Summary

**The five MCP supervision commands now operate as a bounded independent consumer of the exact capture hub used by dashboard viewers, with real safe stream outcomes, independent progress, and production dual-gateway lifecycle proof.**

## Performance

- **Duration:** 1h51min
- **Started:** 2026-07-22T10:56:51Z
- **Completed:** 2026-07-22T12:48:06Z
- **Tasks:** 3
- **Files modified:** 18 including nested Chromium sources, exported patches, planning state, and this summary

## Accomplishments

- Implemented create, start, snapshot, diff, and end compatibility semantics against the existing exact-target capture hub. Create opens the local Control Panel without returning a code; start attaches one `kAgentCompatibility` consumer and returns its real baseline.
- Added settled Agent no-change wakeups and current-baseline reads without weakening dashboard long-poll semantics. Navigation, gaps, and overflow continue to require a real safe resynchronization baseline.
- Kept compatibility session state bounded to the shared-hub token, exact stable tab, generation, expiry, and pending request bookkeeping. Replacement start and all terminal conditions detach only the Agent consumer and leave dashboard viewers untouched.
- Projected real hub baseline/diff values into the closed Agent DTO and preflighted serialization before hub acknowledgment. A serialization failure cannot advance the internal cursor, and dashboard authority fields remain structurally absent.
- Proved one dashboard plus one Agent consumer across three server-released DOM mutations. Both receive the same safe mutation, progress independently, survive the other consumer ending, and share one renderer Enable/APC recapture owner.
- Exercised navigation/resync, true post-consumption no-change, owner loss, exact target close, privacy exclusions, and final renderer disable behavior in the real browser fixture.
- Drove real authenticated `/v1/supervision` and `/v1/agent/command` requests through the production main-extra-parts composition. Dashboard unbind completes one pending diff exactly once, ends its owned viewer, Agent unbind makes later MCP work typed unavailable, and session close releases the remaining hub.

## Task Commits

Each TDD task was committed atomically in nested Chromium and immediately exported as an exact source patch in the root repository:

1. **Task 1 (RED): Specify real five-operation semantics on the shared hub** — nested `abdebbb608`; patch tracking `2013ee545`; stable patch ID `282c61e938a884169873b72208d5ee8301a529a6`
2. **Task 2 (GREEN): Attach Agent consumers and serialize actual hub outcomes** — nested `6cfb78834b`; patch tracking `426fec20c`; stable patch ID `8ee2602ef1c343879327781195300f141cd530c4`
3. **Task 3 (GREEN): Prove simultaneous dashboard and MCP consumers on real mutations** — nested `cbe1f662e1`; patch tracking `734fb15ab`; stable patch ID `1b09ae8589edb4f95f8462bf15385ad55a35dd74`

## Files Created/Modified

- `prometheus_supervision_capture_hub.h` / `.cc` — Current-baseline reads, Agent-only settled no-change wakeups, and first-capture ordering that never exposes a plausible empty baseline.
- `prometheus_supervision_profile_service.h` / `.cc` — Exact owner validation, bounded compatibility token map, all five real semantics, serialization-before-ack reads, generation fencing, and terminal cleanup.
- `prometheus_agent_transport_codec.cc` and codec tests — Closed safe baseline/diff/no-change/end projection and recursive authority/content exclusion.
- `prometheus_supervision_profile_service_unittest.cc` — Real shared baseline/diff/no-change/snapshot/end, replacement, gap/resync, rollback, owner mismatch, expiry, shutdown, and pending-callback coverage.
- `prometheus_supervision_capture_hub_browsertest.cc` — Mixed dashboard/Agent real-mutation, independent cursor/end, navigation, owner-loss, target-close, privacy, and single-capture proof.
- `prometheus_agent_gateway_browsertest.cc` — Authenticated production dashboard and Agent HTTP paths, pending dashboard cancellation, ordered dual unbind, and typed unavailable behavior.
- `prometheus_browser_main_extra_parts.h` / `.cc` — Narrow production-composition browser-test binding seam and dashboard-session termination during composition shutdown.
- Chromium Prometheus `BUILD.gn` — Agent codec, tab-list, and common constant dependencies required by the profile-owned implementation.
- `patches/0030`, `0031`, and `0032` — Exact ordered RED, GREEN semantics, and live-browser patch exports.

## Decisions Made

- Agent compatibility is only another consumer kind on the existing per-tab hub. The service cannot instantiate a capture owner or retain renderer, Mojo, tree, history, epoch, sequence, or exported cursor state.
- The authenticated Agent session must already own the exact live tab. Compatibility never claims or transfers ownership, and mismatch terminates its existing consumer before returning `TAB_NOT_OWNED`.
- Snapshot reads the hub's real current safe baseline. Diff returns the actual next batch, a typed resync requirement, or true no-change only after the consumer has no readable batch and no capture is unsettled.
- The closed Agent serializer is the commit boundary for internal cursor progress. Only a successfully serializable baseline or diff is acknowledged.
- Composition shutdown cancels dashboard waits and ends every dashboard session it owns before invalidating callbacks. Agent dispatch is then explicitly unbound, preserving ordered teardown while keeping subsystem dependencies neutral.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Missing production lifecycle seam] Added a narrow main-extra-parts browser-test binding API**

- **Found during:** Task 3 production dual-binding proof
- **Issue:** The production composition and gateway are intentionally private, so the live test could not attach its authenticated loopback fixture or explicitly perform the required dashboard-then-Agent unbind sequence.
- **Fix:** Added narrow test-only bind and Agent-unbind methods that delegate to the exact production composition and dispatcher storage; no concrete supervision edge was added to Agent or gateway sources.
- **Verification:** The live HTTP test reaches the exact regular-profile service through both production callbacks, and all sole-bridge/GN architecture guards pass.
- **Committed in:** nested `cbe1f662e1`; patch tracking `734fb15ab`

**2. [Rule 1 - Lifecycle resource leak] Ended composition-owned dashboard sessions during shutdown**

- **Found during:** Task 3 ordered dashboard unbind
- **Issue:** Composition shutdown cancelled pending waits and erased wire owners but left their service-owned dashboard consumers attached until TTL expiry.
- **Fix:** End each live owned dashboard session after pending cancellation and before owner-map/weak-callback invalidation.
- **Verification:** Dashboard unbind leaves only the Agent token, the pending HTTP diff completes once, and closing the Agent session releases the final hub.
- **Committed in:** nested `cbe1f662e1`; patch tracking `734fb15ab`

**3. [Rule 1 - Browser fixture blockers] Replaced unsafe DTO copying and synchronized server mutations through hub evidence**

- **Found during:** Task 3 live mixed-consumer verification
- **Issue:** `TestFuture<AgentRouteResult>` copied a large live baseline DTO and crashed, while a later Agent read could race the page's asynchronous application of a released server response.
- **Fix:** Serialize the one-shot result inside its completion callback and retain only a small observation; wait for the real hub capture counter before reading the Agent's second mutation.
- **Verification:** The final mixed browser case passes without injection, synthetic observers, crashes, or timing-only sleeps.
- **Committed in:** nested `cbe1f662e1`; patch tracking `734fb15ab`

**4. [Rule 1 - Privacy fixture conflict] Served a dedicated safe mixed-consumer page**

- **Found during:** Task 3 compatibility start
- **Issue:** The existing hub privacy fixture deliberately contains visible password/payment/OTP labels. The closed compatibility codec correctly rejects those forbidden markers even though their values are redacted.
- **Fix:** Preserve the original sensitive page for its privacy test and serve a separate real embedded-server page for mixed compatibility mutations. The verifier rejected and prevented a temporary script-removal approach.
- **Verification:** Anti-injection guards pass; the original hub privacy proof remains intact; the mixed compatibility path returns real safe baselines and diffs.
- **Committed in:** nested `cbe1f662e1`; patch tracking `734fb15ab`

---

**Total deviations:** 4 auto-fixed (1 missing test seam, 1 lifecycle leak, 2 browser-fixture blockers).
**Impact on plan:** All fixes were required to exercise the requested production paths and fail-closed lifecycle. They did not broaden compatibility authority or weaken privacy, ownership, or architecture boundaries.

## Issues Encountered

- The verifier's synthetic unit fixture did not provide the newly referenced tab-list mock dependency. Unit tests inject the same narrow local-UI opener seam, while production continues to open the exact Browser's Control Panel through `TabListInterface`.
- The first mixed browser run exposed the intended strict sensitive-marker rejection; no production privacy rule was relaxed.
- A server response can complete before its JavaScript continuation mutates the DOM. The final test waits on the hub's real capture instrumentation rather than sleeps or renderer-side script probes.

## Test Evidence

- The retained RED gate selected five compatibility/codec tests. The codec case passed and the four named service semantic cases failed only through their intended missing-behavior assertions.
- Task 2's exact service/codec gate selected and passed 14 tests covering all five semantics, real mutation/no-change/resync, rollback, replacement, teardown, and privacy.
- Task 3's exact browser gate selected and passed two tests: `DashboardAndAgentConsumers*` and `SupervisionCommandSemantics*`.
- The final broader service/codec regression again selected and passed all 14 tests after browser lifecycle changes.
- Static gates passed for sole capture ownership, sole composition bridge, exact Agent dispatch, gateway-neutral DTO/codec layering, GN dependencies, privacy, and anti-injection browser evidence.
- Reviewed build metadata and Blink artifacts remained byte-identical: `.ninja_log` `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`; dylib `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`; TOC `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`.
- All three exported patches have stable IDs exactly matching their nested commits, and reverse-apply checks pass.
- Root and nested `git diff --check` passed; the nested implementation tree was clean before summary creation.

Human UAT was not run and is not claimed. Later Phase 21 plans own visible browser state, remote action consent, and complete milestone UAT.

## User Setup Required

None. No credentials, external services, listeners, dashboards, or configuration are required.

## Next Phase Readiness

Plan 21-13 can promote the five now-real supervision tools in the dependency-free Node catalog. The browser owns all target, stream, and cursor authority; MCP receives only the closed safe results established here.

No blockers or threat flags remain. SUP-01, SUP-02, SUP-03, and SUP-05 are progressed but intentionally remain phase-level incomplete until final Phase 21 verification.

## Self-Check: PASSED

- FOUND: ordered nested commits `abdebbb608`, `6cfb78834b`, and `cbe1f662e1`
- FOUND: nonempty exact patch exports `0030`, `0031`, and `0032`
- VERIFIED: stable patch IDs exactly match each nested commit and reverse application succeeds
- VERIFIED: five real Agent compatibility semantics on the shared exact-target capture hub
- VERIFIED: one dashboard plus one Agent consumer across real mutations with independent cursor/end state
- VERIFIED: navigation/resync, true no-change, owner loss, target close, privacy, and final disable behavior
- VERIFIED: both production gateway bindings, pending dashboard cancellation, ordered dual unbind, and typed later failure
- VERIFIED: 2 focused browser tests and 14 final service/codec tests pass
- VERIFIED: source architecture, GN layering, diff, patch, metadata, and immutable-build-artifact guarantees
- VERIFIED: nested Chromium implementation tree clean before summary creation

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-22*
