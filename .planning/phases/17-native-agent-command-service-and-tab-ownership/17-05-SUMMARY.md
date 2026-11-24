---
phase: 17-native-agent-command-service-and-tab-ownership
plan: 05
subsystem: browser-agent-audit-internal-surfaces
tags: [chromium, prometheus, audit, webui, side-panel]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Plan 17-04 route service facade and browser route tests.
provides:
  - Metadata-only `AgentRouteAuditRecord` and bounded `AgentRouteAuditLog`.
  - Audit recording for successful and failed service routes.
  - Internal-surface routes for Prometheus new tab, control panel, and side panel.
  - Unit coverage for audit bounds and disallowed metadata fields.
  - Browser coverage for Prometheus WebUI route targets, side-panel entry opening, and unsupported-route audit safety.
affects: [phase-17, phase-18-page-adapter, phase-19-mcp-bridge]

tech-stack:
  added: []
  patterns:
    - Bounded ring-buffer style audit log.
    - Allowlisted metadata-only route audit records.
    - Explicit internal-surface adapters using existing WebUI and side-panel helpers.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Audit records store route/session/target/error/timing/changed-state metadata only; request URLs and WebUI/page content are not recorded."
  - "Prometheus new-tab and control-panel routes open browser WebUI tabs through `OpenURLParams`."
  - "Prometheus side-panel route uses the existing Phase 16 side-panel helper and does not mutate side-panel WebUI state."

patterns-established:
  - "`PrometheusAgentService::FinishRoute()` sets elapsed time and records audit metadata for every route result."
  - "`AgentRouteAuditLog::Append()` rejects changed-state metadata containing prompt/secret/page/vault/provider/raw-url/DOM-text terms."
  - "Internal surface browser tests inspect committed WebUI URLs and the visible side-panel WebView."

requirements-completed:
  - AGENT-03
  - AGENT-07
  - AGENT-08

duration: 12 min
completed: 2026-07-07
---

# Phase 17-05: Audit and Internal Surfaces Summary

**Secrets-safe route audit metadata and explicit Prometheus WebUI/side-panel route adapters**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-07T09:10:25Z
- **Completed:** 2026-07-07T09:22:47Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `AgentRouteAuditRecord` and bounded `AgentRouteAuditLog` with insertion-order recent-record retention.
- Added audit metadata safety checks for disallowed prompt, secret, page text, vault, provider key, raw URL, and DOM text terms.
- Wired `PrometheusAgentService` to finish every route through a common audit/timing path.
- Implemented `open_prometheus_new_tab`, `open_prometheus_control_panel`, and `open_prometheus_side_panel`.
- Added audit unit tests and browser tests for internal WebUI targets, side-panel display, and unsupported-route audit safety.

## Task Commits

1. **Tasks 1-3: Audit log, internal-surface routes, tests/GN** - `5f73b8a84d` (feat)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.h` - Audit record/log API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc` - Bounded log and metadata safety implementation.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc` - Audit unit coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h` - Audit accessor, route finish/audit helpers, internal-surface helpers.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc` - Audit recording and internal-surface route implementations.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - Internal-surface and audit browser tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Added audit source set and dependencies.

## Decisions Made

- Audit stores browser/window/tab identifiers and changed-state metadata only; it intentionally does not persist request URLs, prompts, page text, DOM text, secrets, vault values, or provider keys.
- Unsupported page actions remain typed `UNSUPPORTED_ROUTE` failures until Phase 18 provides page adapters and action verification.
- Side-panel route opens the already registered Prometheus Assistant side-panel entry using the existing helper path from Phase 16.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced stale side-panel entry path**
- **Found during:** Task 2 research
- **Issue:** The planned `chrome/browser/ui/views/side_panel/side_panel_entry.h` path does not exist in this checkout.
- **Fix:** Used the actual `chrome/browser/ui/side_panel/side_panel_entry.h` path and existing helper APIs.
- **Verification:** Build and browser tests passed.
- **Committed in:** `5f73b8a84d`

**2. [Rule 3 - Blocking] Used actual WebUI constants header**
- **Found during:** Task 2 implementation
- **Issue:** Prometheus WebUI URL constants are in `chrome/common/webui_url_constants.h`, not `chrome/common/url_constants.h`.
- **Fix:** Included and referenced the actual constants header.
- **Verification:** Build and WebUI route browser tests passed.
- **Committed in:** `5f73b8a84d`

**3. [Rule 3 - Blocking] Fixed side-panel WebContents assertion path**
- **Found during:** Browser-test execution
- **Issue:** `SidePanelUI::GetWebContentsForTest()` returned null for the helper-opened Assistant entry path even though the side-panel entry was showing.
- **Fix:** Matched Phase 16 browser tests by inspecting the visible `BrowserView` side-panel `WebView`.
- **Verification:** `./out/Default/browser_tests --gtest_filter='*PrometheusAgentInternalSurface*:*PrometheusAgentService*'` passed, 7/7 tests.
- **Committed in:** `5f73b8a84d`

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** No scope reduction; fixes aligned the plan with current Chromium APIs and established test patterns.

## Issues Encountered

- Initial browser-test construction used a vexing-parse form for `TestNavigationObserver`; fixed with named `GURL` variables before verification.
- Browser tests emitted non-fatal process/GPU test harness logs; focused tests passed.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default prometheus_unittests browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentAudit*:*PrometheusAgent*'` - passed, 21/21 tests.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusAgentInternalSurface*:*PrometheusAgentService*'` - passed, 7/7 tests.
- `cd .context/chromium/src && git diff --check` - passed.
- Acceptance scans confirmed audit/service symbols and internal-surface changed-state strings. Forbidden metadata terms appear only in rejection tests/checks, not in service changed-state output.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-06 can run the full Phase 17 gate, export the Chromium patch series, and close out the phase.

## Self-Check: PASSED

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Completed: 2026-07-07*
