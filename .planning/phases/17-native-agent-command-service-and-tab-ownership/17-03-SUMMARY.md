---
phase: 17-native-agent-command-service-and-tab-ownership
plan: 03
subsystem: browser-agent-tab-ownership
tags: [chromium, prometheus, tabs, ownership, unowned-user-data]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Plans 17-01 and 17-02 route/error/session primitives.
provides:
  - Tab-attached Prometheus agent ownership data.
  - Typed cross-session control and release denials.
  - `PrometheusTabState` backed by browser-owned tab data.
  - Unit coverage for ownership policy and WebContents-to-tab state lookup.
affects: [phase-17, phase-18-page-adapter, phase-19-mcp-bridge]

tech-stack:
  added: []
  patterns:
    - `ui::ScopedUnownedUserData` for tab-attached feature lookup.
    - Explicit caller/service ownership for tab data lifetime.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc

key-decisions:
  - "Do not hide tab-data ownership in a global store; the service/test owner owns the data object while `ScopedUnownedUserData` attaches lookup to the tab."
  - "Avoid a GN dependency cycle by keeping `prometheus_agent_tab_data` link-independent from `prometheus_tab_state.cc`."

patterns-established:
  - "Cross-session tab control returns `TAB_NOT_OWNED` through `AgentRouteResult`."
  - "`PrometheusTabState` reads only `PrometheusAgentTabData::From(tab)` after `MaybeGetFromContents()`."

requirements-completed:
  - AGENT-04
  - AGENT-05
  - AGENT-08

duration: 8 min
completed: 2026-07-07
---

# Phase 17-03: Tab Ownership Data Summary

**Browser-owned tab ownership metadata feeding trusted `PrometheusTabState` with typed cross-session denial**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-07T08:43:10Z
- **Completed:** 2026-07-07T08:51:15Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `PrometheusAgentTabData` with owner session ID, owner label, automation, supervision, and health fields.
- Added claim/control/release helpers that deny mismatched sessions with `TAB_NOT_OWNED`.
- Updated `GetPrometheusTabStateForWebContents()` to resolve `tabs::TabInterface::MaybeGetFromContents()` and read only attached Prometheus tab data.
- Added unit tests for ownership policy, field conversion, safe defaults, caller-label distrust, and trusted browser-owned tab state.

## Task Commits

1. **Tasks 1-3: Tab ownership data, tab-state wiring, tests/GN** - `3ec04dc9e7` (feat)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h` - Tab ownership data API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc` - Tab-attached lookup and ownership policy implementation.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data_unittest.cc` - Ownership policy tests.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc` - WebContents-to-tab lookup and trusted state read.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc` - Trusted/untrusted tab-state tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Added tab-data target and test dependencies.

## Decisions Made

- `PrometheusAgentTabData` uses `ScopedUnownedUserData` for lookup but leaves object ownership explicit to the caller/service. This avoids a hidden process-global store with unclear tab destruction semantics.
- `PrometheusAgentTabData::GetOrCreateForTab()` returns a `unique_ptr` for the caller to own; `ForTabForTesting()` uses the same path for unit tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unavailable `CHECK_DEREF` helper**
- **Found during:** Task 1 (tab-attached ownership data)
- **Issue:** This Chromium revision does not expose `CHECK_DEREF`.
- **Fix:** Added a small local `GetHostForTab()` helper using `CHECK(tab)` before accessing the tab's `UnownedUserDataHost`.
- **Files modified:** `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc`
- **Verification:** `../../depot_tools/autoninja -C out/Default prometheus_unittests` succeeded.
- **Committed in:** `3ec04dc9e7`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No behavior or scope change; the fix was required for Chromium compilation.

## Issues Encountered

- Initial build failed on unavailable `CHECK_DEREF`. Fixed as documented above.
- `ScopedUnownedUserData` is not an owner, so tab-data lifetime remains explicit in caller/service storage instead of being hidden in a global store.
- GN dependency cycle avoided by having `prometheus_tab_state` depend on `prometheus_agent_tab_data`, while the data target uses only the header-level `PrometheusTabState` type.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default prometheus_unittests` - passed.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentTabData*:*PrometheusTabState*'` - passed, 8/8 tests.
- `cd .context/chromium/src && git diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-04 can enforce ownership through `PrometheusAgentTabData` and keep service-owned tab-data lifetimes explicit while implementing route actions.

## Self-Check: PASSED

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Completed: 2026-07-07*
