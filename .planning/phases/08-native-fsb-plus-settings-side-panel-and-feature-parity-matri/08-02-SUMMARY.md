---
phase: 08
plan: 02
subsystem: agent-runtime-policy
tags: [agent, runtime, policy, settings, tdd, execution-mode, mcp]
dependency_graph:
  requires:
    - 08-01: agentcommandrouter agentCap Settings read, PERMISSION_BLOCKED, PROVIDER_NOT_CONFIGURED patterns
  provides:
    - finishTask execution-mode metrics (executionMode, providerAvailable, unavailableReason)
    - agentPolicyValue helper for Settings-backed policy reads
    - routeGetAgentPolicy and routeSetAgentPolicy tool routes
    - get_agent_policy and set_agent_policy in health tools array
  affects:
    - 08-03: side panel can read execution-mode from task outcomes
    - 08-04: FSB parity matrix can verify agent policy routes
tech_stack:
  added: []
  patterns:
    - Settings beginGroup/endGroup for PrometheusRuntime/Policy reads in both runtime and router
    - Execution-mode defaulting in finishTask (local fallback when no executionMode in metrics)
    - vaultBoundary locked invariant: always "native_only" when Settings key absent or empty
    - PERMISSION_BLOCKED for secret-named keys in set_agent_policy
key_files:
  created: []
  modified:
    - falkon/src/lib/agent/agentruntime.cpp
    - falkon/src/lib/agent/agentruntime.h
    - falkon/src/lib/agent/agentcommandrouter.cpp
    - falkon/src/lib/agent/agentcommandrouter.h
    - falkon/autotests/agentcommandroutertest.cpp
    - falkon/autotests/agentcommandroutertest.h
decisions:
  - finishTask defaults executionMode to "local" with providerAvailable=false and unavailableReason="provider_not_configured" when metrics does not contain executionMode
  - routeGetAgentPolicy exposes m_agentCap (live runtime cap) not the Settings value as the authoritative agentCap in the response
  - vaultBoundary is a locked invariant defaulting to "native_only"; any empty or absent Settings value returns "native_only"
  - routeSetAgentPolicy uses writeAudit (not agentRuntime appendLog which is private) for the policy update audit trail
metrics:
  duration: 5min
  completed_date: "2026-06-16"
  tasks: 2
  files: 6
---

# Phase 8 Plan 02: AgentRuntime Execution-Mode Metrics and AgentCommandRouter Policy Routes Summary

Settings-backed agent policy with persistent get/set routes, typed error codes, and execution-mode recording in task outcomes.

## What Was Built

### Task 1: AgentRuntime finishTask execution-mode metrics and agentPolicyValue helper

Extended `finishTask` in `agentruntime.cpp` to merge execution-mode fields into the stored task metrics:

- If the caller-supplied `metrics` QJsonObject does not contain `executionMode`, inserts: `executionMode="local"`, `providerAvailable=false`, `unavailableReason="provider_not_configured"`, and empty `provider`/`model` strings. This satisfies FSBP-04 by ensuring every completed task outcome carries execution-mode provenance.
- If `metrics` already contains `executionMode`, passes through `provider`, `model`, `providerAvailable`, `unavailableReason` as supplied.
- Added private `agentPolicyValue(key, defaultValue)` method in both `.cpp` and `.h`: reads from `Settings` group `PrometheusRuntime/Policy`, returns `{key, value}` envelope.
- `runtimeChanged()` emission unchanged.
- Method signature of `finishTask` unchanged.

### Task 2: AgentCommandRouter Settings-backed policy routes and focused tests (TDD)

**RED phase commit:** Added three failing test methods to `agentcommandroutertest.cpp` and `agentcommandroutertest.h`:
- `testGetAgentPolicy`: verified route missing, test failed.
- `testSetAgentPolicyPersists`: verified route missing, test failed.
- `testExecutionModeLocalFallback`: immediately passed (finishTask from Task 1 already supplies execution-mode).

**GREEN phase commit:** Implemented in `agentcommandrouter.cpp` and `agentcommandrouter.h`:

1. Added dispatch branches in `routeForSession` for `get_agent_policy` and `set_agent_policy`.
2. Appended `get_agent_policy` and `set_agent_policy` to health tools array (in same order as dispatch additions).
3. `routeGetAgentPolicy`: reads `PrometheusRuntime/Policy` Settings group, returns `agentCap` (authoritative `m_agentCap`), `internalSurfaceControl`, `tabOwnershipEnforcement`, `visualFeedback`, `telemetry`, `vaultBoundary` (locked default `"native_only"` — never absent or empty), `supervisionPairing`, `vaultAutofillConfirmation`.
4. `routeSetAgentPolicy`: validates `agentCap` range 1..16; rejects `secret`, `apiKey`, `password`, `token` parameter names with `PERMISSION_BLOCKED`; persists accepted keys via Settings `beginGroup/setValue/endGroup`; updates `m_agentCap` live if `agentCap` is in params; emits audit entry via `writeAudit`.
5. Declared both route methods in `agentcommandrouter.h` following existing route signature pattern.

All 12 tests pass: 7 pre-existing + 3 new.

## Verification Results

```
100% tests passed, 0 tests failed out of 1
Total Test time (real) = 0.32 sec
12 passed, 0 failed, 0 skipped
```

Acceptance criteria verified:
- `rg 'PrometheusRuntime/Policy/agentCap' agentcommandrouter.cpp` — 2 matches
- `rg 'PERMISSION_BLOCKED' agentcommandrouter.cpp` — 2 matches (openInternalSurface + setAgentPolicy)
- `rg 'PROVIDER_NOT_CONFIGURED' agentcommandrouter.cpp` — 2 matches (routeProviderConfig)
- `rg 'get_agent_policy' agentcommandrouter.cpp` — 2 matches (dispatch + health array)
- `rg 'native_only' agentcommandrouter.cpp` — 3 matches (vaultBoundary default pattern)
- `rg 'testGetAgentPolicy|testSetAgentPolicy|testExecutionMode' agentcommandroutertest.cpp` — 3 matches
- `rg 'executionMode' agentruntime.cpp` — 3 matches
- `rg 'PROVIDER_NOT_CONFIGURED' agentruntime.cpp` — 1 match (comment)
- `rg 'agentPolicyValue' agentruntime.h` — 1 match

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] appendLog is private in AgentRuntime**
- **Found during:** Task 2 implementation
- **Issue:** Plan specified `mApp->agentRuntime()->appendLog(...)` for policy audit in `routeSetAgentPolicy`, but `appendLog` is a private method in `AgentRuntime` and cannot be called from the router.
- **Fix:** Used `writeAudit(id, tool, true, ...)` instead, which is the router's own audit mechanism and achieves the same audit trail goal.
- **Files modified:** `falkon/src/lib/agent/agentcommandrouter.cpp`
- **Commit:** 8ccf91398

## TDD Gate Compliance

- RED gate commit: `d0390d6b6` — `test(08-02): add failing tests for get/set_agent_policy routes and execution-mode fallback`
- GREEN gate commit: `8ccf91398` — `feat(08-02): add routeGetAgentPolicy, routeSetAgentPolicy, dispatch, and health tools entries`

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes beyond those already registered in the plan's `<threat_model>`:
- T-08-02: `routeSetAgentPolicy` caps agentCap to 1..16 and blocks secret-named keys with PERMISSION_BLOCKED.
- T-08-02b: `routeGetAgentPolicy` returns only bool/int/string policy values, never raw secrets.
- T-08-02c: `finishTask` executionMode is set by trusted runtime code, not by MCP caller-supplied metrics.

## Self-Check: PASSED

Files verified:
- `falkon/src/lib/agent/agentruntime.cpp` — FOUND
- `falkon/src/lib/agent/agentruntime.h` — FOUND
- `falkon/src/lib/agent/agentcommandrouter.cpp` — FOUND
- `falkon/src/lib/agent/agentcommandrouter.h` — FOUND
- `falkon/autotests/agentcommandroutertest.cpp` — FOUND
- `falkon/autotests/agentcommandroutertest.h` — FOUND

Commits verified:
- `90863238e` feat(08-02): agentruntime execution-mode + agentPolicyValue — FOUND
- `d0390d6b6` test(08-02): failing tests RED phase — FOUND
- `8ccf91398` feat(08-02): routeGetAgentPolicy, routeSetAgentPolicy — FOUND
