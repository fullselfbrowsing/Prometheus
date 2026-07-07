---
phase: 17
slug: native-agent-command-service-and-tab-ownership
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
---

# Phase 17 - Validation Strategy

> Per-phase validation contract for Chromium-native Prometheus agent routing,
> sessions, tab ownership, and browser-owned tab/window actions.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Chromium `prometheus_unittests` and `browser_tests` |
| Build dir | `.context/chromium/src/out/Default` |
| Main unit filter | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'` |
| Main browser filter | `./out/Default/browser_tests --gtest_filter='*PrometheusAgent*:*PrometheusTabCommands*'` |
| Root gates | `check-chromium-env.sh`, `check-falkon-gpl-guard.sh`, `verify-artifact-isolation.sh` |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 17-01-01 | 01 | 1 | AGENT-01, AGENT-07, AGENT-08 | unit | `autoninja -C out/Default prometheus_unittests && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentRoute*'` | pending |
| 17-02-01 | 02 | 1 | AGENT-04, AGENT-06, AGENT-07 | unit | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentSession*'` | pending |
| 17-03-01 | 03 | 2 | AGENT-04, AGENT-05, AGENT-08 | unit/browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentTabData*:*PrometheusTabState*'` | pending |
| 17-04-01 | 04 | 2 | AGENT-01, AGENT-02, AGENT-03, AGENT-05, AGENT-07, AGENT-08 | browser | `./out/Default/browser_tests --gtest_filter='*PrometheusAgentService*'` | pending |
| 17-05-01 | 05 | 3 | AGENT-03, AGENT-07, AGENT-08 | unit/browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentAudit*' && ./out/Default/browser_tests --gtest_filter='*PrometheusAgentInternalSurface*'` | pending |
| 17-06-01 | 06 | 4 | AGENT-01..AGENT-08 | gate | full Phase 17 build/test/root gates plus patch export | pending |

## Required Assertions

- Route names are allowlisted and unknown routes return typed errors.
- Caller-provided client labels cannot authorize sessions or tab ownership.
- Session caps and reconnect/expired-session errors are represented.
- Ownership is keyed to stable tab identity, not mutable tab index.
- Cross-agent tab control returns `TAB_NOT_OWNED`.
- Browser-owned tab actions mutate only the intended tab/window.
- Internal surfaces are opened through explicit adapters.
- Route results and audit records contain no raw secrets, prompts, or page text.

## Manual-Only Verifications

None planned for Phase 17. All service behavior must be testable through unit
or browser tests.

## Validation Sign-Off

- [x] Automated verify commands or explicit manual checks exist for each plan.
- [x] Sampling continuity: no 3 consecutive plans without automated verify.
- [x] Wave 0 uses existing Phase 15/16 Chromium test infrastructure.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.
