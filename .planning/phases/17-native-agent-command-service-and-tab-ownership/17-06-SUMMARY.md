---
phase: 17-native-agent-command-service-and-tab-ownership
plan: 06
subsystem: phase-closeout-and-patch-export
tags: [chromium, prometheus, verification, patches, preservation]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Plans 17-01 through 17-05 Chromium implementation commits.
provides:
  - Full Phase 17 automated gate logs with explicit `EXIT_CODE=0` lines.
  - Exported six-patch Chromium series from the Phase 16 tip through Phase 17.
  - Phase 17 verification report.
  - Phase 17 code-review fix and re-verification evidence.
  - Preservation ledger update for native route/session/ownership/audit evidence.
  - Carry-forward boundary for Phase 18 and later parity work.
affects: [phase-17, phase-18-page-adapter, phase-19-mcp-bridge, phase-20-runtime]

requirements-completed:
  - AGENT-01
  - AGENT-02
  - AGENT-03
  - AGENT-04
  - AGENT-05
  - AGENT-06
  - AGENT-07
  - AGENT-08

duration: 6 min
completed: 2026-07-07
---

# Phase 17-06: Validation, Patch Export, and Preservation Summary

**Full Phase 17 closeout for Chromium-native agent command routing and tab ownership**

## Performance

- **Completed:** 2026-07-07T09:43:28Z
- **Tasks:** 3
- **Files modified:** 5 tracked doc/artifact areas plus exported patches

## Accomplishments

- Ran the full Phase 17 build, unit, browser, root, and whitespace gate set with
  explicit log files and `EXIT_CODE=0` markers.
- Fixed Phase 17 code-review findings for profile-scoped targets, unsafe URL
  schemes, and ownership of Prometheus internal-surface tabs.
- Exported the six Chromium commits for Phase 17 from `b46e7a5d1e..ad736125ee`.
- Verified the exported patches are non-empty and limited to Prometheus
  Chromium source/test/GN paths.
- Updated the Falkon-to-Chromium preservation ledger with Phase 17 evidence.
- Marked all Phase 17 validation rows complete and created the final
  verification report.
- Kept later-phase page/MCP/runtime/supervision/extension work explicitly open.

## Patch Export

Exported to:

`.planning/phases/17-native-agent-command-service-and-tab-ownership/patches/`

Files:

1. `0001-feat-17-01-add-Prometheus-agent-route-spine.patch`
2. `0002-feat-17-02-add-Prometheus-agent-session-registry.patch`
3. `0003-feat-17-03-add-Prometheus-tab-ownership-data.patch`
4. `0004-feat-17-04-add-Prometheus-agent-route-service.patch`
5. `0005-feat-17-05-audit-agent-routes-and-internal-surfaces.patch`
6. `0006-fix-17-review-harden-Prometheus-agent-route-boundari.patch`

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default chrome browser_tests prometheus_unittests` - passed, log `phase17-06-build.log`, `EXIT_CODE=0`.
- `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'` - passed, 25/25 tests, log `phase17-06-prometheus-unittests.log`, `EXIT_CODE=0`.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusAgent*:*PrometheusTabCommands*'` - passed, 13/13 tests, log `phase17-06-browser-tests.log`, `EXIT_CODE=0`.
- `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/verify-artifact-isolation.sh` - passed, log `phase17-06-root-gates.log`, `EXIT_CODE=0`.
- `git -C .context/chromium/src diff --check && git diff --check` - passed, log `phase17-06-diff-checks.log`, `EXIT_CODE=0`.

## Preservation Update

The preservation ledger now points to `17-VALIDATION.md`,
`17-VERIFICATION.md`, the six exported Phase 17 patches, and the Phase 17 gate
logs as evidence for the native command route, session, tab ownership, internal
surface, typed-error, and audit-record portions of the migration.

## Carry-Forward

- Phase 18: DOM/page reads, frame targeting, JS execution, page actions, waits,
  and mutation verification.
- Phase 19: MCP bridge, tool schema compatibility, visual-session fields,
  reconnect grace, and diagnostics.
- Phase 20: task runtime, providers, vault/secret storage, memory, site guides,
  logs, metrics, and control-panel data.
- Phase 21: visible supervision, pairing, revocation, remote control, and stale
  message protection.
- Phase 22: extension ecosystem support and extension permission boundaries.
- Manual desktop visual UAT remains tied to later binary/package validation, not
  Phase 17 service-unit behavior.

## User Setup Required

None.

## Next Phase Readiness

Phase 18 can start from the Phase 17 route/session/ownership service and add
page adapter routes for DOM snapshots, page reads, JS execution, and verified
page actions.

## Self-Check: PASSED

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Completed: 2026-07-07*
