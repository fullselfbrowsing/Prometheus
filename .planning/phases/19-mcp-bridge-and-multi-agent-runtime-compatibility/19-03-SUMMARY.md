---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 03
subsystem: profile-session-lifetime
tags: [chromium, keyed-service, sessions, ownership, security, tdd]

requires:
  - phase: 19-02
    provides: Closed native route and result contracts
provides:
  - Regular-profile-only keyed native agent authority
  - Opaque session resume/touch/close and deterministic ten-second expiry
  - Default eight-session cap with clamped 1..64 configuration seam
  - Exact-session tab ownership release on graceful close and expiry
affects: [19-04, 19-05, 19-07]

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_factory.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_factory.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc

requirements-completed: []
requirements-progressed: [MCP-01, MCP-07]

completed: 2026-07-13
---

# Phase 19 Plan 03: Profile-Keyed Session Lifetime Summary

**Agent authority now lives in a regular-profile keyed service with opaque resume, deterministic expiry, a bounded production cap, and exact-owner tab cleanup.**

## Accomplishments

- Added `PrometheusAgentProfileServiceFactory` using `ProfileSelections::BuildForRegularProfile()` and explicit off-the-record denial.
- Pinned every session and route to one profile service and selected tabbed browsers only from that profile's `ProfileBrowserCollection`.
- Added opaque-id resume, touch, close, and explicit expiry reporting with an exact ten-second boundary and injected-time tests.
- Added production defaults of eight sessions and a clamped 1..64 test/config seam.
- Released only the matching session's tab ownership on close or expiry, allowing safe reclaim by another live session.
- Swept expiry before create, resume, touch, close, and execute; display labels and profile paths never grant authority.

## Nested Chromium Commits

1. `e5450d075f` — `test(19-03): specify profile session and ownership lifetime`
2. `d45867601f` — `fix(19-03): release ownership on session close and expiry`
3. `35edc573cb` — `feat(19-03): add profile-keyed Prometheus agent service`

## Verification

- `autoninja -C out/Default prometheus_unittests browser_tests` — passed.
- Session/tab-data units — 17/17 passed with injected time and no sleeps.
- Profile-service plus existing agent-service browser inventory — 10/10 passed serially, including two regular profiles, OTR denial, cap, close, expiry, reclaim, and cross-profile targeting.
- Nested `git diff --check` — passed; nested worktree clean.

## Deviations

None. The revised plan requirement to sweep expiry before `close` is implemented and covered by `CloseOperationSweepsExpiryBeforeReclaim`.

## Next Plan Readiness

Plan 19-04 can consume one profile-pinned service and stable ownership lifetime while replacing the structured-tab, internal-surface, and element-read placeholders. Plan 19-05 can expose the same keyed service without selecting authority from labels or profile paths.

## Self-Check: PASSED

- FOUND: all three nested commits and five new profile-service files.
- VERIFIED: 17 focused units and 10 browser tests.
- VERIFIED: regular-profile-only factory, exact-owner cleanup, cap, and ten-second opaque resume.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-13*
