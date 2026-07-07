---
phase: 17-native-agent-command-service-and-tab-ownership
plan: 01
subsystem: browser-agent-routing
tags: [chromium, prometheus, agent-routes, typed-errors]

requires:
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    provides: Prometheus Chromium WebUI hosts and browser-backed surface URLs.
provides:
  - Typed Prometheus agent route names and parser helpers.
  - Stable FSB-compatible agent error-code strings.
  - Metadata-only route request/result structs for later service plans.
  - Unit coverage for route parsing, error serialization, and result factories.
affects: [phase-17, phase-18-page-adapter, phase-19-mcp-bridge]

tech-stack:
  added: []
  patterns:
    - Focused Chromium `source_set` under `chrome/browser/prometheus`.
    - Stable enum-to-string compatibility helpers for future MCP mappings.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Use `//components/tabs:public` as the actual Chromium tab handle header dependency."
  - "Keep route results metadata-only: target IDs, error code, recovery text, elapsed time, and changed-state values."

patterns-established:
  - "Agent route strings are lower snake case and must parse through `AgentRouteNameFromString`."
  - "Agent error strings are uppercase compatibility tokens returned by `AgentErrorCodeToString`."

requirements-completed:
  - AGENT-01
  - AGENT-07
  - AGENT-08

duration: 5 min
completed: 2026-07-07
---

# Phase 17-01: Route Spine Summary

**Typed Prometheus agent route/result primitives with stable compatibility strings and unit coverage**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-07T08:32:39Z
- **Completed:** 2026-07-07T08:37:26Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `AgentRouteName`, `AgentErrorCode`, `AgentTarget`, `AgentRouteRequest`, and `AgentRouteResult`.
- Added route parsing/serialization and uppercase error-code serialization helpers.
- Wired `prometheus_agent_route` into `prometheus_unittests`.
- Covered known route strings, unknown route denial, every error-code string, and success/failure result factories.

## Task Commits

1. **Task 1 and Task 2: Route spine plus tests/GN wiring** - `158351b0cb` (feat)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h` - Route, target, request, and result declarations.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc` - Route parser and stable string helpers.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route_unittest.cc` - Route/result unit tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Added route source set and unit-test wiring.

## Decisions Made

- Used `tabs::TabHandle` for stable tab target identity in the route target descriptor.
- Kept the route result free of raw request content and limited to metadata needed by later service, audit, and MCP layers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected Chromium tabs GN dependency**
- **Found during:** Task 2 (route/result unit tests and GN wiring)
- **Issue:** The plan named `//components/tabs`, but the local Chromium BUILD exposes public tab headers as `//components/tabs:public`.
- **Fix:** Updated `prometheus_agent_route` deps to `//components/tabs:public`.
- **Files modified:** `.context/chromium/src/chrome/browser/prometheus/BUILD.gn`
- **Verification:** `../../depot_tools/autoninja -C out/Default prometheus_unittests` succeeded.
- **Committed in:** `158351b0cb`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No behavior or scope change; this was required for GN regeneration.

## Issues Encountered

- Initial build failed during GN regeneration because `//components/tabs` was not a target. Fixed as documented above.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default prometheus_unittests` - passed.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentRoute*'` - passed, 6/6 tests.
- `cd .context/chromium/src && git diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-02 can build the browser-issued session registry on top of `AgentErrorCode`, `AgentRouteResult`, and the stable compatibility strings.

## Self-Check: PASSED

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Completed: 2026-07-07*
