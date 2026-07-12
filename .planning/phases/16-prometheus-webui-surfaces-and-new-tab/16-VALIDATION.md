---
phase: 16
slug: prometheus-webui-surfaces-and-new-tab
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
completed: 2026-07-07
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
| 16-01-01 | 01 | 1 | WEBUI-01, WEBUI-05, WEBUI-06 | build/browser | `autoninja -C out/Default chrome browser_tests && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*'` | passed |
| 16-02-01 | 02 | 2 | WEBUI-01, WEBUI-02, WEBUI-03 | browser | `./out/Default/browser_tests --gtest_filter='*PrometheusNewTab*'` | passed |
| 16-03-01 | 03 | 2 | WEBUI-03, WEBUI-05 | browser/ui | `./out/Default/browser_tests --gtest_filter='*PrometheusSidePanel*'` | passed |
| 16-04-01 | 04 | 3 | WEBUI-04, WEBUI-05 | browser | `./out/Default/browser_tests --gtest_filter='*PrometheusControlPanel*'` | passed |
| 16-05-01 | 05 | 3 | WEBUI-05, WEBUI-06, WEBUI-07 | unit/static/browser | `autoninja -C out/Default prometheus_unittests browser_tests && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusWebUI*'` | passed |
| 16-06-01 | 06 | 4 | WEBUI-01..WEBUI-07 | gate | full Phase 16 build/test/root gates plus patch export | passed |

## Required Assertions

- All Prometheus WebUI hosts/routes create a WebUI controller.
- Required labels render for start page, side panel modes, and nine control
  panel sections.
- Ask FSB prompt handoff does not place prompt text in URL/query/fragment.
- Side-panel toolbar button opens Prometheus WebUI content.
- Resource tests prove Phase 16 HTML/CSS/JS resources are packaged.
- Static scan flags load-bearing remote resources.
- No tests or fixtures expose provider keys, vault secrets, or pairing secrets.

## Phase 16-06 Gate Evidence

Automated gates passed on 2026-07-07:

- `.context/chromium/src/out/Default/phase16-06-build.log` - `chrome browser_tests prometheus_unittests`, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase16-06-prometheus-unittests.log` - full `prometheus_unittests`, 22/22 tests passed, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase16-06-browser-tests.log` - `browser_tests --gtest_filter='*Prometheus*WebUI*:*Prometheus*NewTab*:*Prometheus*SidePanel*:*Prometheus*ControlPanel*'`, 7/7 tests passed, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase16-06-webui-resource-gate.log` - Prometheus WebUI resource gate passed for five files, `EXIT_CODE=0`.
- `.context/chromium/src/out/Default/phase16-06-root-gates.log` - Chromium environment, GPL guard, and artifact isolation gates, `EXIT_CODE=0`.
- `.planning/phases/16-prometheus-webui-surfaces-and-new-tab/patches/` - 9 non-empty Chromium patches exported from `a4423116ff..HEAD`.

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
- [x] Phase 16 automated gate logs contain `EXIT_CODE=0`.
- [x] Phase 16 Chromium patch series exported.
- [x] Human desktop visual UAT disposition recorded: dark/light start-page polish, side-panel density, and responsive control-panel layout are deferred to the final release review as non-blocking.

**Approval:** approved 2026-07-07
