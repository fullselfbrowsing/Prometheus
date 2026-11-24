---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 03
subsystem: browser-page-adapter
tags: [chromium, cpp, webcontents, renderframehost, inner-text, async-routing]

# Dependency graph
requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Browser-issued sessions, profile-scoped targets, stable tab ownership, typed route failures, and content-safe audit finalization
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 01
    provides: Typed page request/result contracts, page route names, and page-specific error codes
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 02
    provides: Deterministic read-page fixture and route-backed browser-test harness
provides:
  - Browser-process PrometheusPageAdapter facade with live WebContents and RenderFrameHost resolution
  - Typed page/frame error helpers for invalid, stale, restricted, permission, verification, and repeated-action failures
  - Callback-based page-route dispatch with no production nested RunLoop
  - Authorized read_page extraction through content_extraction::GetInnerText with a 24,000-byte default bound
  - Route-level unit and browser coverage for truncation, ownership, internal-page denial, and audit safety
affects: [18-04, 18-05, 18-06, 18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Page operations resolve WebContents and RenderFrameHost at call time and never retain raw page/frame pointers across calls.
    - PrometheusAgentService page routes are callback-based; test-only synchronous ergonomics use base::test::TestFuture.
    - Page payloads stay in AgentRouteResult::page_result while changed_state and audit records contain stable metadata constants only.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_error.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_error.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Established callback-first signatures immediately: PrometheusPageAdapter::Execute and PrometheusAgentService::ExecuteRoute both return void and take a base::OnceCallback<void(AgentRouteResult)> completion callback."
  - "Kept synchronous test ergonomics at the test boundary with base::test::TestFuture; production page dispatch contains no nested base::RunLoop or blocking wait."
  - "Allowed read_page only for live active HTTP(S) frames in the authorized primary page; fenced, sandboxed, prerendered, cross-origin, stale, crashed, and foreign-page targets return typed failures without fallback."
  - "Used max_chars=24000 when no read bound is supplied and UTF-8-safe deterministic truncation with explicit truncated and omitted_count metadata."

patterns-established:
  - "Async page route finalization: adapter completion returns to PrometheusAgentService::OnPageRouteComplete, which calls FinishRoute exactly once to add elapsed timing and audit metadata."
  - "Frame policy: default to GetPrimaryMainFrame; explicit process/routing identifiers are validated at time of use, while unresolved document tokens fail stale rather than falling back."
  - "Content boundary: visible text is returned only in page_result.visible_text; successful audit changed_state is exactly visible_text_returned."

requirements-completed: []
requirements-progressed: [PAGE-01, PAGE-08]

# Metrics
duration: 21min
completed: 2026-07-12
---

# Phase 18 Plan 03: Browser Page Adapter and Bounded Read Page Summary

**Added a frame-policy-aware browser page adapter and an authorized, bounded `read_page` route over Chromium inner-text extraction, with callback-only production dispatch and content-free audit metadata.**

## Performance

- **Duration:** 21min
- **Started:** 2026-07-12T12:01:15Z
- **Completed:** 2026-07-12T12:22:23Z
- **Tasks:** 3 completed
- **Files created/modified:** 10

## Accomplishments

- Added `PrometheusPageAdapter` and typed page-error helpers that resolve only live active frames in the authorized primary page and explicitly deny stale, crashed, prerendered, fenced, sandboxed, foreign, and cross-origin targets.
- Routed all Phase 18 page route names through the existing Phase 17 session, target, profile, and ownership authority; `read_page` then extracts renderer inner text asynchronously and returns deterministic truncation metadata.
- Kept page content exclusively in `AgentRouteResult::page_result.visible_text`; route audit records receive only `visible_text_returned` or typed failure metadata.
- Added passing unit and browser coverage for string bounds, frame-error mapping, audit safety, bounded reads, cross-session ownership denial, and internal-page denial.
- Converted the page route chain to callbacks ahead of Plan 18-05, eliminating the synchronous-plan contradiction without introducing a production blocking loop.

## Task Commits

Each TDD step was committed atomically inside the nested `.context/chromium/src` Chromium checkout:

1. **Task 1 RED: Add failing page-adapter unit tests** - `d46bb04d56` (test)
2. **Task 1 GREEN: Add adapter facade and typed frame errors** - `9442f0c779` (feat)
3. **Task 2 RED: Add failing route-level read-page browser test** - `1d0dd2b25c` (test)
4. **Task 2 GREEN: Route bounded asynchronous text extraction** - `9c47bd9cad` (feat)
5. **REFACTOR: Apply Chromium formatting without behavior changes** - `a8432d7271` (refactor)
6. **Task 3: Add ownership and internal-page denial coverage** - `b44860772e` (test)

**Plan metadata:** this root planning commit

Task 3's new tests were immediately green because Task 2 had already established the Phase 17 ownership and normal-page permission behavior they verify; no additional production change was necessary after that expected-green investigation.

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_error.h/.cc` - Typed page/frame failure helpers mapped to stable `AgentErrorCode` values and recovery guidance.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h/.cc` - Callback-based page facade, frame policy, URL policy, UTF-8-safe output bounding, and `GetInnerText` completion mapping.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_unittest.cc` - Truncation, typed error, and audit-safe changed-state coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h/.cc` - Callback public route entrypoint, page-route validation/ownership path, adapter ownership, and exactly-once completion/audit finalization.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - TestFuture-based helper adapted to the callback public API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` - TestFuture helper plus bounded-read, two-session ownership, internal-page, and audit assertions.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Page adapter source set and focused unit-test wiring.

## Decisions Made

- `PrometheusPageAdapter::Execute(...)` and `PrometheusAgentService::ExecuteRoute(...)` are callback-based now; later Phase 18 plans must extend these committed signatures rather than reintroducing synchronous production dispatch.
- Numeric explicit frame identifiers resolve through `RenderFrameHost::FromID` and are checked against the authorized WebContents and primary page. A document token that cannot yet be mapped by APC fails as stale and never falls back to the main frame.
- Normal page reads are restricted to HTTP(S); `chrome://`, `chrome-untrusted://`, `devtools://`, `file://`, `data:`, `javascript:`, extension, Prometheus runtime, and other non-web schemes are denied before extraction.
- `content_extraction::GetInnerText` failure (renderer crash or shutdown) maps to a typed stale-target failure, while successful content is bounded before it enters the route result.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Converted the page route chain to callbacks ahead of Plan 18-05**
- **Found during:** Task 2 (`read_page` service dispatch)
- **Issue:** Plan 18-03 declared synchronous by-value `Execute`/`ExecuteRoute` signatures, but Chromium's `GetInnerText` is inherently callback-based. Blocking it with a nested production `base::RunLoop` would violate Chromium architecture and the explicit Plan 18-05 calling-convention gate.
- **Fix:** Established callback-based public adapter/service signatures immediately, routed asynchronous completion through `OnPageRouteComplete` and `FinishRoute` exactly once, and converted both browser-test helpers to `base::test::TestFuture<AgentRouteResult>`.
- **Files modified:** `prometheus_page_adapter.h/.cc`, `prometheus_agent_service.h/.cc`, `prometheus_agent_service_browsertest.cc`, `prometheus_page_adapter_browsertest.cc`, `BUILD.gn`
- **Verification:** Combined build passed; focused unit and ReadPage browser suites passed; static scan found no production `base::RunLoop`; service/adapter key links verified 2/2.
- **Committed in:** `9c47bd9cad` (format-only follow-up `a8432d7271`)

---

**Total deviations:** 1 auto-fixed (1 blocking architecture mismatch).
**Impact on plan:** The externally observable route behavior is unchanged, production dispatch is non-blocking, and Plan 18-05's required async conversion is already complete. No page/MCP/runtime scope was added.

## Issues Encountered

- Focused browser tests emitted Chromium's known non-fatal `waitpid(...): No child processes` teardown log; all selected tests exited successfully.
- Task 3's coverage was expected-green after investigation because the required ownership and internal-page behavior was implemented in Task 2.

## Verification

- `../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageAdapter*:*PrometheusPageError*'` - passed, 3/3.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*ReadPage*'` - passed, 3/3.
- Forbidden production scan for `ExecuteJavaScript`, `ExecuteJavaScriptForTests`, and `content/public/test` in `prometheus_page_adapter.cc` - no matches.
- Production blocking scan for `base::RunLoop` in the adapter/service - no matches.
- Plan-specified `git diff --check` - passed.
- Post-implementation `verify key-links` - passed, 2/2.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-05 can build bounded DOM and compact snapshots on the committed callback chain without repeating its planned async conversion. Plan 18-04 follows afterward and can add the permissioned renderer/Mojo JavaScript seam against the same adapter signature. PAGE-01 and PAGE-08 remain open until full Phase 18 verification; this plan records progress only.

## Self-Check: PASSED

- FOUND: all five key created files.
- FOUND: nested Chromium commits `d46bb04d56`, `9442f0c779`, `1d0dd2b25c`, `9c47bd9cad`, `a8432d7271`, and `b44860772e`.
- PASSED: combined build, 3 focused unit tests, 3 focused browser tests, forbidden-API scan, production-RunLoop scan, diff check, and 2/2 key links.
- CLEAN: nested Chromium working tree after all task commits.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
