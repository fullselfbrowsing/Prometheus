---
phase: 16
slug: prometheus-webui-surfaces-and-new-tab
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
---

# Phase 16 - Validation Strategy

> Per-phase validation contract for Chromium-backed Prometheus WebUI surfaces.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Chromium `prometheus_unittests` and `browser_tests` |
| Build dir | `.context/chromium/src/out/Default` |
| Main filter | `./out/Default/browser_tests --gtest_filter='*Prometheus*WebUI*:*Prometheus*NewTab*:*Prometheus*SidePanel*:*Prometheus*ControlPanel*'` |
| Root gates | `check-chromium-env.sh`, `check-falkon-gpl-guard.sh`, `verify-artifact-isolation.sh` |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 16-01-01 | 01 | 1 | WEBUI-01, WEBUI-05, WEBUI-06 | build/browser | `autoninja -C out/Default chrome browser_tests && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*'` | pending |
| 16-02-01 | 02 | 2 | WEBUI-01, WEBUI-02, WEBUI-03 | browser | `./out/Default/browser_tests --gtest_filter='*PrometheusNewTab*'` | pending |
| 16-03-01 | 03 | 2 | WEBUI-03, WEBUI-05 | browser/ui | `./out/Default/browser_tests --gtest_filter='*PrometheusSidePanel*'` | pending |
| 16-04-01 | 04 | 3 | WEBUI-04, WEBUI-05 | browser | `./out/Default/browser_tests --gtest_filter='*PrometheusControlPanel*'` | pending |
| 16-05-01 | 05 | 3 | WEBUI-05, WEBUI-06, WEBUI-07 | unit/static/browser | `autoninja -C out/Default prometheus_unittests browser_tests && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusWebUI*'` | pending |
| 16-06-01 | 06 | 4 | WEBUI-01..WEBUI-07 | gate | full Phase 16 build/test/root gates plus patch export | pending |

## Required Assertions

- All Prometheus WebUI hosts/routes create a WebUI controller.
- Required labels render for start page, side panel modes, and nine control
  panel sections.
- Ask FSB prompt handoff does not place prompt text in URL/query/fragment.
- Side-panel toolbar button opens Prometheus WebUI content.
- Resource tests prove Phase 16 HTML/CSS/JS resources are packaged.
- Static scan flags load-bearing remote resources.
- No tests or fixtures expose provider keys, vault secrets, or pairing secrets.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual |
|----------|-------------|------------|
| Start page visual polish in dark/light themes | WEBUI-01, WEBUI-02 | Native screenshot capture was blocked in Phase 15; human desktop review may be needed. |
| Side panel four-mode visual density at 320px | WEBUI-03 | Requires real side-panel host inspection. |
| Control panel responsive rail/select behavior | WEBUI-04 | Requires visual comparison at 320px, 720px, and wide widths. |

## Validation Sign-Off

- [x] Automated verify commands or explicit manual checks exist for each plan.
- [x] Sampling continuity: no 3 consecutive plans without automated verify.
- [x] Wave 0 uses existing Phase 14/15 infrastructure.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.
