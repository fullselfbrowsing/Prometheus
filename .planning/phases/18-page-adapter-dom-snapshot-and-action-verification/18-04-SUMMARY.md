---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 04
subsystem: browser-page-execution
tags: [chromium, cpp, mojo, isolated-world, javascript, audit]

# Dependency graph
requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 03
    provides: Callback-based page adapter, normal-page/frame policy, and browser-test harness
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 05
    provides: Committed callback route signatures and document-scoped snapshot foundations
provides:
  - Prometheus-owned associated Mojo contract for renderer script execution
  - Dedicated isolated-world execution with bounded JSON result serialization
  - Permission, URL, size, timeout, disconnect, and navigation-race enforcement
  - Content-free execute_js audit state and deterministic unit/browser coverage
affects: [18-06, 18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Browser-owned validation precedes associated-interface dispatch into a dedicated renderer isolated world.
    - Ref-counted per-request executors arbitrate response, timeout, disconnect, and navigation through one completion path.
    - JavaScript values and errors stay in bounded AgentPageResult payloads; audit state uses stable constants only.

key-files:
  created:
    - .context/chromium/src/chrome/common/prometheus_render_frame.mojom
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.h
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_js_executor_unittest.cc
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/execute_js.html
  modified:
    - .context/chromium/src/chrome/common/BUILD.gn
    - .context/chromium/src/chrome/common/chrome_isolated_world_ids.h
    - .context/chromium/src/chrome/android/java/src/org/chromium/chrome/browser/common/ChromeIsolatedWorldIds.java
    - .context/chromium/src/chrome/renderer/BUILD.gn
    - .context/chromium/src/chrome/renderer/chrome_content_renderer_client.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc

key-decisions:
  - "Run execute_js only through ISOLATED_WORLD_ID_PROMETHEUS and the PrometheusRenderFrame associated interface; production code never calls Chromium's restricted or test-only ExecuteJavaScript APIs."
  - "Keep each executor alive across asynchronous races with adapter ownership plus retained ref-counted callbacks, while a single Complete path consumes the callback exactly once."
  - "Treat an oversized or otherwise discarded renderer value as verification failure, never as a successful empty result."
  - "A 10-second timer bounds the browser caller's wait; it does not claim to interrupt JavaScript already executing in the renderer."

patterns-established:
  - "Execution gate order: request shape -> explicit JavaScript permission -> normal-page URL -> live frame -> renderer IPC."
  - "Completion arbitration: response, timeout, Mojo disconnect, and cross-document navigation all stop/reset resources before invoking the stored callback."
  - "Audit contract: success changed_state is exactly js_executed; failure changed_state is empty, while bounded diagnostics remain in page_result.javascript_error."

requirements-completed: []
requirements-progressed: [PAGE-04]

# Metrics
duration: 29min
completed: 2026-07-12
---

# Phase 18 Plan 04: Permissioned Isolated-World JavaScript Summary

**Added an explicit-permission `execute_js` route over a Prometheus-owned renderer/Mojo seam, with isolated-world execution, bounded result capture, exactly-once asynchronous completion, and content-free audit records.**

## Performance

- **Duration:** 29min
- **Started:** 2026-07-12T13:09:20Z
- **Completed:** 2026-07-12T13:38:20Z
- **Tasks:** 3 completed
- **Files created/modified:** 16

## Accomplishments

- Registered `PrometheusRenderFrame` on every renderer frame and executed authorized scripts in `ISOLATED_WORLD_ID_PROMETHEUS` through Blink's asynchronous `RequestExecuteScript` API.
- Added browser-side validation for explicit permission, normal-page URLs, non-empty script input, and the 20,000-byte script bound before renderer dispatch.
- Captured JSON values and bounded errors in `AgentPageResult`, rejected discarded oversized renderer values, and kept scripts/results out of `changed_state` and audit metadata.
- Made asynchronous execution race-safe across renderer response, timeout, disconnect, same-frame navigation, and concurrent requests with one exactly-once completion path.
- Added deterministic unit and real-browser coverage for success, throw/failure, missing permission, internal-page denial, size bounds, stale navigation, discarded results, and callback uniqueness.

## Task Commits

Each TDD/implementation step was committed atomically inside the nested `.context/chromium/src` checkout:

1. **RED: Specify permissioned JavaScript behavior** - `755d8641f0` (test)
2. **Task 1: Add the isolated renderer script contract** - `631db55630` (feat)
3. **Tasks 2/3 GREEN: Execute permissioned page JavaScript** - `28ee2469bc` (feat)
4. **Correctness fix: Attach errors to asynchronous failures** - `ba2b5a8988` (fix)

**Plan metadata:** this root planning commit

## Files Created/Modified

- `chrome/common/prometheus_render_frame.mojom` and `chrome/renderer/prometheus_render_frame_observer.{h,cc}` - Associated renderer contract, isolated-world Blink dispatch, JSON serialization, and bounded failure mapping.
- `chrome/common/chrome_isolated_world_ids.h` and its Android Java mirror - Prometheus-owned isolated-world identifier kept synchronized for Chromium lint invariants.
- `chrome/browser/prometheus/prometheus_page_js_executor.{h,cc}` - Per-request Mojo remote, weak-document/navigation tracking, timeout/disconnect arbitration, retained lifetime, and exactly-once completion.
- `chrome/browser/prometheus/prometheus_page_adapter.{h,cc}` - Request gates, concurrent executor ownership, route result mapping, and stable audit state.
- `prometheus_page_js_executor_unittest.cc`, `prometheus_page_adapter_browsertest.cc`, and `execute_js.html` - Pure validation/race tests plus real renderer execution coverage against deterministic DOM data.
- Browser/common/renderer BUILD files and `chrome_content_renderer_client.cc` - Mojo generation, source/test wiring, and per-frame observer construction.

## Decisions Made

- Preserved the committed callback-based `PrometheusPageAdapter::Execute` and test-only `base::test::TestFuture` signatures; no blocking production wrapper was introduced.
- Used a dedicated isolated world rather than the main world. Tests therefore evaluate literals and fixture DOM state, not page-defined JavaScript globals that an isolated world cannot observe.
- Stored active executors in an adapter map and retained them across each asynchronous callback so concurrent calls are independent and completion cannot destroy the executor mid-callback.
- Stopped the timer, cleared/reset the Mojo remote, detached observation, and moved the callback before user code runs. Late competing signals become no-ops.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Replaced unreachable main-world test globals**
- **Found during:** Browser-test design
- **Issue:** The planned fixture functions on `window` live in the page's main world and are not visible from the required isolated world.
- **Fix:** Used a literal/DOM-derived object for successful evaluation and an inline throwing IIFE for failure coverage.
- **Verification:** All five execute_js browser tests passed in the dedicated isolated world.
- **Committed in:** `755d8641f0`

**2. [Rule 2 - Lifetime/Security] Added durable, concurrent, exactly-once executor ownership**
- **Found during:** Browser-side executor implementation
- **Issue:** A temporary executor would be destroyed before Mojo response, while response, timeout, disconnect, and navigation can race.
- **Fix:** Combined adapter-owned concurrent executors with ref-counted retained callbacks and one resource-resetting `Complete` path; added a callback-uniqueness test.
- **Verification:** `CompletesExactlyOnce` and the same-frame navigation browser test passed.
- **Committed in:** `28ee2469bc`

**3. [Rule 1 - Correctness] Failed oversized discarded results explicitly**
- **Found during:** Result-mapping review
- **Issue:** Mapping an oversized discarded value as `ok=true` with an empty payload could become a false success.
- **Fix:** The renderer returns `ok=false` with a bounded error and the browser defensively rejects every empty/discarded value.
- **Verification:** `RejectsDiscardedOversizedRendererResult` passed.
- **Committed in:** `28ee2469bc`

**4. [Rule 3 - Required lint coupling] Updated the Android isolated-world mirror**
- **Found during:** Chromium isolated-world registry review
- **Issue:** `chrome_isolated_world_ids.h` has a synchronized Java mirror enforced by Chromium lint conventions, but the mirror was absent from the plan's file list.
- **Fix:** Added the Prometheus ID and shifted the unused extensions ID in `ChromeIsolatedWorldIds.java` with the C++ enum.
- **Verification:** Combined Chromium build and diff checks passed.
- **Committed in:** `631db55630`

**5. [Rule 1 - Diagnostic contract] Populated page errors for timeout and stale navigation**
- **Found during:** Final failure-path audit
- **Issue:** Typed timeout/stale route failures did not also populate the promised `page_result.javascript_error` field.
- **Fix:** Added bounded diagnostics and direct stale-payload unit coverage.
- **Verification:** Focused unit tests passed 8/8.
- **Committed in:** `ba2b5a8988`

---

**Total deviations:** 5 auto-fixed (3 correctness, 1 lifetime/security, 1 required lint coupling).
**Impact on plan:** The fixes strengthen the intended isolated execution and result/audit contracts. No MCP behavior, bundled CLI/runtime, in-browser terminal, alternate engine, or engine-toggle scope was added; external MCP compatibility remains unchanged.

## Issues Encountered

- The initial renderer build passed a span into `WebString::FromUtf16`; Chromium's API accepts the script string/view directly. Correcting that call produced a clean build.
- A Promise-based stale-navigation test waited for timeout because the renderer did not respond before navigation; observing target-frame cross-document navigation made the stale failure immediate and deterministic.
- Focused browser tests emitted Chromium's known non-fatal `waitpid(...): No child processes` and occasional GPU mailbox teardown logs; all selected tests exited successfully.

## Verification

- `../../depot_tools/autoninja -C out/Default chrome browser_tests prometheus_unittests` - passed, final run reported `ninja: no work to do`.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageJsExecutor*:*PrometheusPageAdapter*'` - passed, 8/8.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*ExecuteJs*'` - passed, 5/5.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentAudit*'` - passed, 8/8.
- Post-implementation key links - passed, 2/2.
- Restricted/test-only JavaScript API, audit-content, and bundled CLI/runtime/terminal/engine scans - no forbidden matches.
- Chromium environment, GPL guard, artifact isolation, preservation, committed-range diff, and working-tree checks - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-06 can build safe renderer-side actions on the committed page-adapter callback chain and document-scoped ref resolver. PAGE-04 remains open until the full Phase 18 verification plan; this summary records progress only.

## Self-Check: PASSED

- FOUND: all seven created files and nine modified integration/lint files.
- FOUND: four nested Chromium commits from `755d8641f0` through `ba2b5a8988`.
- PASSED: no-work combined build, 21 focused unit/browser/audit tests, four root gates, security/audit scans, diff checks, and 2/2 key links.
- CLEAN: nested Chromium working tree after all task commits.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
