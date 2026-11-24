---
phase: 17-native-agent-command-service-and-tab-ownership
plan: 04
subsystem: browser-agent-service
tags: [chromium, prometheus, browser-service, tabs, sessions]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Plans 17-01 through 17-03 route, session, and tab-ownership primitives.
provides:
  - Browser-process `PrometheusAgentService` facade.
  - Stable target resolution through `tabs::TabHandle` / `tabs::TabInterface`.
  - Session-validated tab/window/navigation route dispatch.
  - Cross-session mutation denial with `TAB_NOT_OWNED`.
  - Browser coverage for list/open/activate/navigate/reload/back/forward/duplicate/move/close routes.
affects: [phase-17, phase-18-page-adapter, phase-19-mcp-bridge]

tech-stack:
  added: []
  patterns:
    - Browser-process service facade with explicit dependencies.
    - Service-owned tab data guarded by tab detach subscriptions.
    - Metadata-only changed-state route results.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn

key-decisions:
  - "Resolve route targets through browser-owned `TabListInterface` and stable tab handles rather than mutable tab indices."
  - "Keep Phase 18 page/content routes unsupported until DOM/page adapters can verify actions."
  - "Erase service-owned `PrometheusAgentTabData` before tab deletion so `UnownedUserDataHost` teardown remains clean."

patterns-established:
  - "`PrometheusAgentService::ExecuteRoute()` validates sessions before dispatch and touches last-seen only after validation succeeds."
  - "Mutating routes call `EnsureCanControl()` before acting and return typed route failures."
  - "Changed-state entries are metadata-only strings such as `tab_opened` and `navigation_started`."

requirements-completed:
  - AGENT-01
  - AGENT-02
  - AGENT-03
  - AGENT-05
  - AGENT-07
  - AGENT-08

duration: 20 min
completed: 2026-07-07
---

# Phase 17-04: Agent Route Service Summary

**Browser-process route facade for authenticated agent sessions, stable tab targets, and safe tab/window/navigation mutations**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-07T08:51:15Z
- **Completed:** 2026-07-07T09:10:25Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `PrometheusAgentService` with `CreateSession`, `CloseSession`, and `ExecuteRoute()` entrypoints over an injected `AgentSessionRegistry`.
- Implemented target resolution for browser/window/session IDs and stable `tabs::TabHandle` targets, including stale/invalid target failures.
- Implemented Phase 17 routes for listing tabs/windows, opening, activating, closing, navigating, reloading, history back/forward, duplicating, and moving tabs to a new window.
- Enforced tab ownership through `PrometheusAgentTabData`, including cross-session `TAB_NOT_OWNED` denials.
- Added browser tests for metadata listing, ownership claim, activation, navigation/history/reload, duplicate, move-to-window, close, and two-session denial.

## Task Commits

1. **Tasks 1-3: Agent service facade, route dispatch, browser tests/GN** - `da0c6a6f7c` (feat)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h` - Agent service API and service-owned tab-data lifetime tracking.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc` - Session validation, target resolution, route dispatch, ownership checks, and metadata-only results.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - Browser coverage for Phase 17 route behavior.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Added `prometheus_agent_service` source set.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Wired service browser tests into the Prometheus browser-test target.

## Decisions Made

- Phase 17 service returns unsupported errors for internal Prometheus surfaces and page/content actions; those remain Phase 17-05 and Phase 18 work.
- Service-owned tab data is erased before explicit `CloseTab()` and on tab deletion via `RegisterWillDetach()`, avoiding stale `ScopedUnownedUserData` attachments.
- Move-to-new-window returns the moved tab's new browser session when Chromium reassigns the tab to a new window.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced stale `browser_finder.h` plan reference**
- **Found during:** Task 2 (tab/window route implementation)
- **Issue:** The planned `chrome/browser/ui/browser_finder.h` path is not present in this Chromium revision.
- **Fix:** Used `GlobalBrowserCollection` and `BrowserWindowInterface` public APIs to resolve browser windows by `SessionID`.
- **Verification:** Build and browser tests passed.
- **Committed in:** `da0c6a6f7c`

**2. [Rule 3 - Blocking] Fixed service-owned tab-data teardown**
- **Found during:** Browser-test execution
- **Issue:** `ScopedUnownedUserData` must be removed before a tab's `UnownedUserDataHost` is destroyed; browser tests crashed at teardown when service-owned tab data outlived the tab.
- **Fix:** Added service-owned tab-data records with `RegisterWillDetach()` subscriptions and erased data before explicit close.
- **Verification:** `./out/Default/browser_tests --gtest_filter='*PrometheusAgentService*'` passed, 4/4 tests.
- **Committed in:** `da0c6a6f7c`

**3. [Rule 3 - Blocking] Fixed `raw_ptr` conditional ambiguity**
- **Found during:** Build
- **Issue:** A ternary expression mixed `BrowserWindowInterface*` and `raw_ptr<BrowserWindowInterface>`.
- **Fix:** Normalized the fallback browser target to a plain pointer before returning success.
- **Verification:** `../../depot_tools/autoninja -C out/Default prometheus_unittests browser_tests` passed.
- **Committed in:** `da0c6a6f7c`

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** No scope reduction; fixes improved lifetime safety and used current Chromium APIs.

## Issues Encountered

- Initial browser tests exposed a real tab-data lifetime bug. The service now unregisters owned user data before tab deletion rather than relying on fixture teardown.
- The Chromium build emitted non-fatal test harness `waitpid(...): No child processes` logs during browser tests; all focused tests passed.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default prometheus_unittests browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'` - passed, 21/21 tests.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusAgentService*'` - passed, 4/4 tests.
- `cd .context/chromium/src && git diff --check` - passed.
- Acceptance scans confirmed required service/test symbols and no prompt/secret/vault/provider/page-text changed-state fields.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-05 can add/audit internal Prometheus surface adapters and permission boundaries on top of the session-validated service facade.

## Self-Check: PASSED

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Completed: 2026-07-07*
