---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 08
subsystem: browser-page-actions
tags: [chromium, cpp, page-actions, javascript, document-identity, verification, audit]

# Dependency graph
requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 05
    provides: Bounded snapshots and document-scoped element refs
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 06
    provides: Safe renderer action IPC over public Blink APIs
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 07
    provides: Page settlement waits and bounded repeated-action history
provides:
  - Fresh APC-backed exact-document action resolution before renderer IPC
  - Retained exactly-once browser action operations with post-action settlement
  - Seven wired action routes plus typed drag and unconditional file-drop denials
  - Compact content-free change reports and third-identical-action rejection
  - Public snapshot-token targeting for same-origin child frames
  - Browser-owned wait and bounded APC read-back for declared JavaScript mutations
  - Runtime denial coverage for cross-origin, sandboxed, fenced, prerendered, detached, and crashed frames
affects: [phase-19-mcp-bridge, PAGE-04, PAGE-05, PAGE-06, PAGE-07, PAGE-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Browser action authority is ref prefix -> fresh APC node -> exact DocumentIdentifier -> live RFH -> requested WeakDocumentPtr equality.
    - Adapter-owned ref-counted operations retain Mojo, waiter, callbacks, and weak document/page identity through one completion funnel.
    - Snapshot document tokens are usable public frame targets; optional process/routing identifiers must resolve to the same live document.
    - Declared JavaScript mutations compare bounded pre/post APC projections after settlement; only a SHA-256 fingerprint survives between captures.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor_unittest.cc
    - .context/chromium/src/chrome/common/prometheus_render_frame.mojom
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.h
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.cc
    - .context/chromium/src/chrome/renderer/prometheus_action_dispatcher.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Record the resolved route-plus-ref fingerprint only after fresh APC and exact-frame validation, immediately before renderer dispatch."
  - "Keep renderer failure details out of browser results and audit metadata; callers receive a stable typed verification failure."
  - "Deny drop_file for empty and non-empty token lists without inspecting or opening any token value; keep drag explicitly unsupported."
  - "Require a fresh APC lookup to return the exact document token encoded in the ref, closing popup node-id/token confusion."
  - "Resolve public snapshot document tokens to live RFHs and require any optional process/routing identity to agree with that document."
  - "Keep mutation verification in the browser process: capture a bounded APC fingerprint before execution, wait for settlement, capture it again, and report verified change or explicit no change."
  - "Remove the unused renderer mutation flag so the isolated-world script seam cannot be mistaken for the verification authority."

patterns-established:
  - "Fresh action chain: bounded request -> live requested document -> fresh APC -> exact ref token/node -> full frame policy -> history -> revalidation -> Mojo -> waiter -> bounded report."
  - "Content-free action metadata: fingerprints use route plus ref; audit uses stable changed-state constants; typed text, keys, options, selectors, page content, scripts, and file tokens are excluded."
  - "Mutation read-back chain: bounded APC fingerprint -> exact weak document -> isolated-world script once -> settlement -> fresh bounded APC fingerprint -> compact content-free report."

requirements-completed: []
requirements-progressed: [PAGE-04, PAGE-05, PAGE-06, PAGE-07, PAGE-08]

# Metrics
duration: 3h49m
completed: 2026-07-12
---

# Phase 18 Plan 08: Verified Page Action Route Wiring Summary

**Wired safe page actions end-to-end and closed formal verification gaps with browser-owned JavaScript mutation read-back plus exhaustive restricted-frame runtime coverage.**

## Performance

- **Duration:** 3h49m
- **Started:** 2026-07-12T14:57:57Z
- **Completed:** 2026-07-12T18:46:47Z
- **Tasks:** 3 completed
- **Nested commits:** 7

## Accomplishments

- Added a ref-counted browser dispatcher that fresh-fetches APC, binds the exact ref token to the returned `DocumentIdentifier`, requires the resulting RFH to match the originally requested `WeakDocumentPtr`, and repeats the full policy check immediately before Mojo dispatch.
- Retained each in-flight action in the page adapter through renderer response, disconnect, waiter completion, cancellation, and final callback, with exactly-once completion and no raw RFH retained across asynchronous work.
- Wired click, type, key, scroll, hover, select, and clear; added compact JSON reports, navigation status for clicks, bounded repeated-action detection before the third dispatch, typed drag rejection, and unconditional file-drop denial without reading token values.
- Completed real browser coverage for navigation clicks, type/clear, selection, scrolling, hover, Enter submission, repeated actions, drag/drop denials, and exact same-origin child-document targeting.
- Closed an independent-review finding in Chromium's popup lookup path by rejecting any node whose returned document token differs from the ref prefix, with a dedicated forged-token regression test.
- Made snapshot-issued document tokens usable as the public child-frame targeting contract, while preserving live/primary/profile/sandbox/fenced/same-origin checks and rejecting inconsistent optional RFH identifiers.
- Added a browser-owned JavaScript mutation verifier that captures bounded SHA-256 APC fingerprints before and after the one allowed script execution, waits for page settlement, preserves the script value, and returns either `js_mutation_verified` or an explicit typed `no_verified_change` result.
- Added same-origin allow coverage plus cross-origin, sandboxed, fenced, prerendered, detached, and crashed target denials, asserting exact errors, empty payload/state, and matching content-free audit records.

## Task Commits

Each implementation step was committed inside the nested `.context/chromium/src` checkout:

1. **Task 1 RED: Specify browser action orchestration** - `2792712b8f` (test)
2. **Task 1 GREEN: Add fresh exact-document action dispatcher** - `4f0e1897e6` (feat)
3. **Tasks 2/3: Wire routes, browser coverage, and review fixes** - `f0c668fce0` (feat)
4. **Verification RED: Specify mutation read-back and restricted-frame behavior** - `b31158ccdb` (test)
5. **Verification GREEN: Add bounded browser-owned JavaScript read-back** - `a1ad6fcf3a` (fix)
6. **Verification hardening: Assert restricted targets return no content** - `4c0a186c6b` (test)
7. **Review fix: Scope read-back to the exact live target document** - `caae2f6a81` (fix)

**Plan metadata:** this root planning commit.

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.h` - retained action-operation contract.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.cc` - fresh APC resolution, renderer dispatch, waiter, report, cancellation, and exactly-once completion.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher_unittest.cc` - request bounds, exact fallback matching, safe reports, typed waits, and late-callback coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h` - adapter-owned action operations and bounded history state.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc` - route mapping, public document-token frame resolution, history wiring, and typed drag/drop denials.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` - nine action cases, audit assertions, and snapshot-token child-frame coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.h` - shared in-memory snapshot-node interface.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc` - shared walk and exact ref-token verification.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc` - serialized-walk equivalence and popup token-confusion regression coverage.
- `.context/chromium/src/chrome/renderer/prometheus_action_dispatcher.cc` - complete RawKeyDown/Char/KeyUp sequence for normal Enter behavior.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - route-specific typed internal-surface denials.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor.{h,cc}` - stage-bounded APC baseline, script IPC, settlement, read-back, cancellation, and exactly-once completion.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor_unittest.cc` - verified-change, explicit-no-change, timeout, missing-read-back, and lifecycle result coverage.
- `.context/chromium/src/chrome/common/prometheus_render_frame.mojom` and `.context/chromium/src/chrome/renderer/prometheus_render_frame_observer.{h,cc}` - simplified script-only renderer seam; verification authority remains in the browser.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - dispatcher source and unit-test wiring.

## Decisions Made

- The caller-provided ref is never durable authority. Its prefix must equal the document returned by fresh APC, that document must resolve inside the owned `WebContents`, and it must equal the requested weak document before and immediately before IPC.
- Selector and accessible-name fallback are bounded to 2,048 in-memory snapshot nodes, require one exact match, and reject truncated or ambiguous results.
- Renderer error text is not propagated across the browser route. This avoids exposing page-derived details while retaining typed failure and recovery guidance.
- File drop remains denied regardless of whether its token list is empty or populated. No file token is interpreted as a path, opened, logged, fingerprinted, or copied into reports.
- Mutation verification never reruns caller JavaScript and never returns the APC projection or its SHA-256 fingerprint. Only compact booleans/stable states cross the route result, while the script value remains in `AgentPageResult`.
- A declared mutation that leaves the bounded observable page projection unchanged is a typed verification failure with `no_verified_change`, not a false success.
- PAGE requirements remain open until the independent Phase 18 verifier signs the complete acceptance map; this plan records progress only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Added a complete keyboard character event**
- **Found during:** `PressKeySubmitsForm` browser coverage
- **Issue:** Raw key down followed directly by key up did not trigger Enter's normal form action.
- **Fix:** Mirrored the established renderer input sequence with a bounded `kChar` event between down and up, re-fetching the widget and checking liveness at every boundary.
- **Verification:** `PressKeySubmitsForm` passed in isolation and in the 28-test browser regression suite.

**2. [Rule 1 - Test correctness] Selected an actionable snapshot node for navigation click**
- **Found during:** focused click browser rerun
- **Issue:** A label-only helper selected a matching text-node ref, which the renderer correctly rejected as a non-element.
- **Fix:** Required the snapshot node's `tag` to be `anchor`, preserving real mouse input dispatch and eliminating the false target.
- **Verification:** click-only passed, then all nine action cases and the full browser suite passed.

**3. [Rule 2 - Security] Bound ref tokens to the exact APC document**
- **Found during:** independent final code review
- **Issue:** Chromium's popup-first `FindNodeWithID` branch can return the popup opener document without using the caller's supplied token, allowing a forged prefix with a colliding node id to reach browser dispatch.
- **Fix:** Required `ResolveSnapshotNodeRef` to compare the returned `DocumentIdentifier::serialized_token()` with the ref prefix before returning a node.
- **Verification:** `RejectsForgedTokenForPopupNodeId` passed, all 62 focused browser-side units passed, and the reviewer confirmed resolution.

**4. [Rule 1 - Contract completeness] Exposed usable same-origin child-frame targeting**
- **Found during:** independent final code review
- **Issue:** The first browser test injected internal process/routing ids even though external clients receive snapshot document tokens.
- **Fix:** Resolved bounded `AgentFrameTarget.document_token` values through the current `WebContents`, required optional RFH identifiers to agree, and changed the test request to derive its token only from the returned snapshot ref.
- **Verification:** exact-child targeting passed with only public route data; default-main mismatch remained a typed stale-target failure with no mutation.

**5. [Rule 3 - Build recovery] Reconstructed the Chromium Siso graph without source loss**
- **Found during:** Task 3 build
- **Issue:** An accidental system `ninja` invocation replaced local dependency/log state and caused the next correct build to treat a large generated graph as stale.
- **Fix:** Stopped the wrong process, removed only its generated Ninja metadata, and allowed the correct Chromium Siso invocation to rebuild once without cleaning source or output artifacts.
- **Verification:** the recovery build exited 0; every later build was incremental and passed.

**6. [Rule 1 - Verification correctness] Implemented the omitted JavaScript mutation read-back contract**
- **Found during:** independent Phase 18 verification
- **Issue:** `verify_mutation` reached the renderer but was ignored, so a mutating script could be reported as successful without settlement, read-back, a change report, or an explicit no-change result.
- **Fix:** Moved verification authority into the browser executor, captured bounded APC fingerprints before/after the one script execution, reused `PrometheusPageWaiter`, added stage-specific timeouts/cancellation, and removed the unused renderer flag.
- **Verification:** 12 focused executor/adapter units and all 7 execute-js browser tests passed, including verified mutation and explicit no-change cases.

**7. [Rule 2 - Security evidence] Exercised every restricted frame gate at runtime**
- **Found during:** independent Phase 18 verification
- **Issue:** production gates existed, but only same-origin success had browser coverage; cross-origin, sandboxed, fenced, prerendered, detached, and crashed targets lacked no-fallback/no-leak evidence.
- **Fix:** Added deterministic browser cases for each state and asserted exact typed errors, no page payload, empty changed state, and matching content-free audit errors.
- **Verification:** the `*Prometheus*Frame*` inventory ran 8/8 successfully.

**8. [Rule 2 - Verification integrity] Scoped read-back and revalidated liveness at every async boundary**
- **Found during:** independent remediation code review
- **Issue:** hashing the whole primary-page APC could let unrelated parent/sibling churn verify a child script, and a weak-valid but crashed RFH needed an explicit live check at read-back completion.
- **Fix:** Added an exact-document bounded snapshot projection, required APC's document map to resolve the same target RFH, revalidated active/live/non-crashed WebContents membership at every stage, and added real child mutation, mutation-enabled stale navigation, and script-timeout browser cases.
- **Verification:** target-projection unit coverage, three focused async browser cases, 67/67 full units, and 37/37 full browser cases passed; independent re-review found no remaining issue.

---

**Total deviations:** 8 auto-fixed (4 correctness/contract, 3 security/evidence, 1 build recovery).
**Impact on plan:** All changes strengthen the requested action and frame contract. No embedded CLI/runtime, terminal, alternate engine, file access, or MCP implementation was added.

## Automated Evidence

- `AI_AGENT=1 ../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests prometheus_action_dispatcher_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPage*:*PrometheusAgent*'` - passed, 67/67.
- `./out/Default/prometheus_action_dispatcher_unittests --gtest_filter='PrometheusActionDispatcherTest.*'` - passed, 2/2.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*Page*:*PrometheusAgentService*' --test-launcher-jobs=1` - passed, 37/37, including all action, mutation-read-back, async-failure, and frame-policy cases.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*ExecuteJs*' --test-launcher-jobs=1` - passed, 9/9.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*Frame*' --test-launcher-jobs=1` - passed, 8/8.
- Fresh-token, public child-frame, exactly-once lifecycle, bounded fallback/history/report, content-free audit, unconditional file denial, actor-independence, and forbidden embedded-runtime scans - passed.
- Independent final code review found two issues; both were fixed, regression-tested, and confirmed resolved on re-review.
- Chromium environment, Falkon GPL guard, artifact isolation, preservation verification, and nested/root diff checks - passed.
- Human visual UAT was not run; Phase 18 has no manual acceptance dependency.

## User Setup Required

None - no external service configuration or human UAT is required.

## Next Phase Readiness

Phase 18 plan execution and automated gap remediation are complete. The independent Phase 18 verifier passed PAGE-01 through PAGE-08 at 8/8, so the PAGE requirements and roadmap phase are complete and Phase 19 is current.

## Self-Check: PASSED

- FOUND: all seven nested commits from `2792712b8f` through `caae2f6a81`.
- PASSED: build, 67 browser-side units, 2 renderer units, 37 browser tests, static security/key-link scans, independent review/re-review, and inherited root gates.
- CLEAN: nested Chromium working tree after the final implementation commit.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
