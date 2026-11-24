---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 02
subsystem: browser-testing
tags: [chromium, cpp, browser-tests, embedded-test-server, html-fixtures]

# Dependency graph
requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Browser-issued sessions, stable tab targets, ownership enforcement, and route execution helpers
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 01
    provides: Typed page-route names, request/result payload contracts, page error vocabulary, and content-safe audit boundaries
provides:
  - Deterministic local HTML fixtures for reads, forms, ARIA, dynamic DOM changes, frames, navigation, scrolling, hover, selection, and drag/drop
  - Reusable PrometheusPageAdapterBrowserTest harness backed by Phase 17 session, route, target, and embedded-test-server helpers
  - Focused fixture smoke coverage in the Chromium browser_tests target
  - Explicit typed-unsupported service behavior for page routes until production adapters land
affects: [18-03, 18-04, 18-05, 18-06, 18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Page-adapter browser fixtures are local, deterministic, content-safe files served by Chromium's embedded test server.
    - Browser tests open and navigate fixture tabs through PrometheusAgentService so the Phase 17 session/target route spine remains exercised.
    - content::EvalJs remains test-only and is used only to assert fixture markers after route-driven navigation.

key-files:
  created:
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/read_page.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/forms.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/dynamic_dom.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/same_origin_frame.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/child_frame.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/sandbox_frame.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/navigation_click.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/drag_drop.html
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn

key-decisions:
  - "The fixture smoke test opens read_page.html and navigates to forms.html through PrometheusAgentService rather than bypassing the Phase 17 route/session/target harness."
  - "All 13 Phase 18 page routes remain explicitly unsupported in production service dispatch until their owning implementation plans land; this plan adds no production page adapter behavior."
  - "Scroll and hover received explicit deterministic fixture state because the plan-level must-have truth is binding even though those markers were absent from the literal acceptance checklist."

patterns-established:
  - "Future Phase 18 browser tests extend PrometheusPageAdapterBrowserTest and use FixtureUrl() for local page-adapter fixtures."
  - "Fixture content may contain test-only page state, but never remote resources, secrets, provider/vault strings, or absolute local paths."

requirements-completed: []
requirements-progressed: [PAGE-01, PAGE-02, PAGE-03, PAGE-04, PAGE-05, PAGE-06, PAGE-07, PAGE-08]

# Metrics
duration: 19min
completed: 2026-07-12
---

# Phase 18 Plan 02: Page Adapter Fixtures and Browser-Test Harness Summary

**Added a deterministic local page-behavior fixture suite and a route-backed Chromium browser-test harness that loads read/form pages through authenticated Prometheus sessions while keeping production page routes explicitly unsupported.**

## Performance

- **Duration:** 19min
- **Started:** 2026-07-12T11:28:26Z
- **Completed:** 2026-07-12T11:47:31Z
- **Tasks:** 3 completed
- **Files created/modified:** 12

## Accomplishments

- Created eight local fixtures covering visible/hidden/long text, ARIA, form inputs and selection, delayed/repeated DOM changes, same-origin and sandbox frames, navigation clicks, deterministic scrolling/hover state, and drag/drop.
- Added `PrometheusPageAdapterBrowserTest` with reusable `CreateSession`, `Request`, `Execute`, `TargetFor`, `active_tab`, `tab_list`, `service`, and `FixtureUrl` helpers.
- Added and passed a focused browser smoke test that opens `read_page.html`, navigates to `forms.html` through Phase 17 service routes, and uses `content::EvalJs` only in test code for marker assertions.
- Restored exhaustive service dispatch after Plan 18-01's enum expansion while deliberately returning typed `UNSUPPORTED_ROUTE` results for every not-yet-implemented page route.

## Task Commits

Each task was committed atomically inside the nested `.context/chromium/src` Chromium checkout:

1. **Task 1: Add local HTML fixtures for all Phase 18 behaviors** - `442bcdc46c` (feat)
2. **Task 2: Add Phase 18 browser-test harness and preserve explicit unsupported page-route behavior** - `b97924ec3f` (test)
3. **Task 3: Wire the browser-test harness into GN** - `cebc4afed4` (chore)
4. **Must-have follow-up: Add explicit scroll and hover fixture state** - `9a4c170cfc` (test)

**Plan metadata:** this root planning commit

## Files Created/Modified

- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/read_page.html` - Visible/hidden/offscreen/long text, ARIA-only control, navigation marker, and deterministic overflow region.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/forms.html` - Labelled input, textarea, select, checkbox, enabled/disabled actions, submit marker, and event-backed hover state.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/dynamic_dom.html` - Repeated mutation counter plus delayed DOM replacement marker.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/same_origin_frame.html` - Parent fixture embedding the local child frame.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/child_frame.html` - Labelled child-frame input and action target.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/sandbox_frame.html` - Opaque-origin sandbox fixture for explicit denial coverage.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/navigation_click.html` - Link/button navigation to `read_page.html#after-click`.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/drag_drop.html` - Draggable source, drop target, and deterministic event log.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` - Shared Phase 18 browser-test harness and fixture smoke test.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc` - Exhaustive typed-unsupported handling for the 13 page-route enums until their implementation plans land.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - Coverage asserting every new page route returns `kUnsupportedRoute` at this stage.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Browser-test source registration.

## Decisions Made

- Used Phase 17 `kOpenTab` and `kNavigate` routes in the fixture smoke test so the harness proves it can create browser-issued sessions, target stable tabs, and execute routes before production page adapters exist.
- Kept the service's new enum cases grouped with `kUnsupportedPageAction`; Plans 18-03 through 18-08 remain the sole owners of production reads, JavaScript, snapshots, actions, waits, and verification.
- Kept fixture scripts inline and deterministic with no external network, secret, provider/vault, or local-file dependency.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Handled Plan 18-01 page enums in the service switch**
- **Found during:** Task 3 browser-test build
- **Issue:** `PrometheusAgentService::ExecuteRoute()` did not handle the 13 page-route enum values added in Plan 18-01, causing `-Wswitch` and missing-return build failures before the new harness could compile.
- **Fix:** Added only the new enum cases to the existing typed-unsupported branch and extended the existing service browser test to assert `kUnsupportedRoute` for each case.
- **Files modified:** `chrome/browser/prometheus/prometheus_agent_service.cc`, `chrome/browser/prometheus/prometheus_agent_service_browsertest.cc`
- **Verification:** `autoninja -C out/Default browser_tests` succeeded; `UnsupportedPageRouteIsAuditedWithoutUnsafeFields` passed.
- **Committed in:** `b97924ec3f`

**2. [Rule 2 - Missing Critical] Added explicit scroll and hover fixtures**
- **Found during:** Final plan-level must-have audit
- **Issue:** The literal marker checklist passed, but the initial fixture set lacked explicit deterministic scroll and hover state named by the plan's binding must-have truth.
- **Fix:** Added an overflow scroll region/destination to `read_page.html` and an event-backed hover target/state to `forms.html`.
- **Files modified:** `chrome/test/data/prometheus/page_adapter/read_page.html`, `chrome/test/data/prometheus/page_adapter/forms.html`
- **Verification:** Static marker/content-safety scans and the focused fixture smoke browser test passed after the commit.
- **Committed in:** `9a4c170cfc`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical).
**Impact on plan:** Both fixes were required to make the planned target buildable and satisfy its complete fixture truth; production page-adapter scope did not expand.

## Issues Encountered

- The first browser-test build exposed the pre-existing exhaustive-switch gap from Plan 18-01; the scoped unsupported-route fix resolved it.
- Focused browser tests emitted Chromium's non-fatal `waitpid(...): No child processes` teardown log, matching prior Phase 17 runs; all selected tests exited successfully.

## Verification

- `test -d .context/chromium/src/chrome/test/data/prometheus/page_adapter` - passed.
- `rg -n "https?://|file:///|SECRET|provider_key|vault" .context/chromium/src/chrome/test/data/prometheus/page_adapter` - returned no matches.
- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusPageAdapterBrowserTest.FixturesLoadFromEmbeddedServer'` - passed, 1/1.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusAgentInternalSurfaceBrowserTest.UnsupportedPageRouteIsAuditedWithoutUnsafeFields'` - passed, 1/1.
- `cd .context/chromium/src && git diff --check -- chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc chrome/browser/ui/views/prometheus/BUILD.gn chrome/test/data/prometheus/page_adapter` - passed.
- Nested Chromium repository status - clean after all four plan commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 18-03 through 18-08 can extend the shared harness and deterministic fixtures for frame policy, page reads, JavaScript, snapshots, safe actions, waits, repeated-action detection, and verification. PAGE-01 through PAGE-08 remain in progress until Phase 18 verification; no requirement is marked complete by this plan.

## Self-Check: PASSED

- FOUND: all eight fixture files under `.context/chromium/src/chrome/test/data/prometheus/page_adapter/`
- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc`
- FOUND: GN source registration in `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn`
- FOUND: commits `442bcdc46c`, `b97924ec3f`, `cebc4afed4`, and `9a4c170cfc`
- PASSED: build, focused smoke test, unsupported-route coverage, content-safety scan, and diff checks

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
