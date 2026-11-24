---
phase: 17
slug: native-agent-command-service-and-tab-ownership
status: passed
verified: 2026-07-07
chromium_patch_range: b46e7a5d1e..ad736125ee
---

# Phase 17 Verification

## Result

Phase 17 passed automated verification for the Chromium-native agent route
spine, authenticated session registry, stable tab ownership data, browser-owned
route service, internal Prometheus surfaces, typed errors, and metadata-only
audit logging.

## Gate Evidence

| Gate | Command | Log | Result |
|------|---------|-----|--------|
| Build | `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default chrome browser_tests prometheus_unittests` | `.context/chromium/src/out/Default/phase17-06-build.log` | `EXIT_CODE=0` |
| Unit tests | `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'` | `.context/chromium/src/out/Default/phase17-06-prometheus-unittests.log` | `EXIT_CODE=0`; 25/25 tests passed |
| Browser tests | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusAgent*:*PrometheusTabCommands*'` | `.context/chromium/src/out/Default/phase17-06-browser-tests.log` | `EXIT_CODE=0`; 13/13 tests passed |
| Root gates | `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/verify-artifact-isolation.sh` | `.context/chromium/src/out/Default/phase17-06-root-gates.log` | `EXIT_CODE=0` |
| Diff checks | `git -C .context/chromium/src diff --check && git diff --check` | `.context/chromium/src/out/Default/phase17-06-diff-checks.log` | `EXIT_CODE=0` |

The browser-test log includes non-fatal Chromium test-harness process cleanup
messages and one existing tab-group event bridge "not implemented" line. The
affected tests all passed and the final command exit code was zero.

## Requirements Coverage

| Requirement | Evidence |
|-------------|----------|
| AGENT-01 | Route schema rejects invalid route names and returns structured route results with typed errors. |
| AGENT-02 | Browser-owned tab/window routes list and mutate tabs through Chromium browser APIs. |
| AGENT-03 | Prometheus internal surfaces open through explicit new-tab, control-panel, and side-panel adapters. |
| AGENT-04 | Sessions are browser-assigned, token-authenticated, bounded, and expiry-aware. |
| AGENT-05 | Tab ownership is stored by stable tab identity and enforced on cross-session control attempts. |
| AGENT-06 | Session caps and reconnect/expiry behavior are represented with typed outcomes. |
| AGENT-07 | Route failures use typed errors and recovery guidance. |
| AGENT-08 | Route results and audit records use metadata-only changed-state fields without prompts, secrets, request URLs, page text, DOM text, vault values, or provider keys. |

## Patch Export

Exported Chromium patch range:

`b46e7a5d1e..ad736125ee`

Chromium commits in range:

1. `158351b0cb feat(17-01): add Prometheus agent route spine`
2. `b7d208c9d4 feat(17-02): add Prometheus agent session registry`
3. `3ec04dc9e7 feat(17-03): add Prometheus tab ownership data`
4. `da0c6a6f7c feat(17-04): add Prometheus agent route service`
5. `5f73b8a84d feat(17-05): audit agent routes and internal surfaces`
6. `ad736125ee fix(17-review): harden Prometheus agent route boundaries`

Exported patch files:

1. `patches/0001-feat-17-01-add-Prometheus-agent-route-spine.patch`
2. `patches/0002-feat-17-02-add-Prometheus-agent-session-registry.patch`
3. `patches/0003-feat-17-03-add-Prometheus-tab-ownership-data.patch`
4. `patches/0004-feat-17-04-add-Prometheus-agent-route-service.patch`
5. `patches/0005-feat-17-05-audit-agent-routes-and-internal-surfaces.patch`
6. `patches/0006-fix-17-review-harden-Prometheus-agent-route-boundari.patch`

Patch count matched the six Phase 17 Chromium commits and every patch was
non-empty. `git apply --numstat` verified the patches are limited to:

- `chrome/browser/prometheus/BUILD.gn`
- `chrome/browser/prometheus/prometheus_agent_audit.*`
- `chrome/browser/prometheus/prometheus_agent_audit_unittest.cc`
- `chrome/browser/prometheus/prometheus_agent_route.*`
- `chrome/browser/prometheus/prometheus_agent_route_unittest.cc`
- `chrome/browser/prometheus/prometheus_agent_service.*`
- `chrome/browser/prometheus/prometheus_agent_service_browsertest.cc`
- `chrome/browser/prometheus/prometheus_agent_session.*`
- `chrome/browser/prometheus/prometheus_agent_session_unittest.cc`
- `chrome/browser/prometheus/prometheus_agent_tab_data.*`
- `chrome/browser/prometheus/prometheus_agent_tab_data_unittest.cc`
- `chrome/browser/prometheus/prometheus_tab_state.cc`
- `chrome/browser/prometheus/prometheus_tab_state_unittest.cc`
- `chrome/browser/ui/views/prometheus/BUILD.gn`

## Preservation Ledger

`.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` now references
Phase 17 evidence for native route/session/ownership/audit behavior and the
exported patch series. The ledger intentionally does not mark later-phase
parity complete for DOM/page action behavior, MCP bridge compatibility,
runtime/provider/vault data, memory/logs, supervision/pairing, or extension
permission boundaries.

## Code Review Fix

The Phase 17 code review initially found three service-boundary issues:

- CR-01: cross-profile/window targeting through global browser lookup.
- CR-02: unsafe special schemes accepted by generic `open_tab` and `navigate`.
- WR-01: Prometheus internal-surface tabs opened without session ownership.

Chromium commit `ad736125ee` fixes these by filtering listed windows to the
source profile, rejecting cross-profile explicit window targets, allowing only
HTTP/HTTPS/about:blank through generic navigation routes, keeping Prometheus
WebUI behind named internal-surface routes, and claiming internal-surface tabs
for the issuing session. The refreshed browser-test gate includes coverage for
all three review findings.

## Carry-Forward

- Phase 18 owns DOM snapshotting, page text, JS execution, page actions, waits,
  stability checks, frame targeting, and action verification.
- Phase 19 owns the MCP bridge, compatibility schemas, visual-session fields,
  reconnect grace, and bridge diagnostics.
- Phase 20 owns provider runtime, task execution, vault/secret storage, memory,
  site guides, logs, diagnostics, token/cost accounting, and control-panel data.
- Phase 21 owns visible supervision, pairing, remote control, revocation, and
  stale-message protection.
- Phase 22 owns extension ecosystem policy and separation from Prometheus agent
  permissions.

## Final Status

`status: passed`
