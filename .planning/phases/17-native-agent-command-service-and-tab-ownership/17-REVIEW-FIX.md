---
phase: 17
status: fixed
review_source: 17-REVIEW.md
fixed_at: 2026-07-07T09:43:28Z
chromium_commit: ad736125ee
findings_fixed:
  critical: 2
  warning: 1
  info: 0
---

# Phase 17 Code Review Fix

## Summary

Phase 17 code review found two critical issues and one warning in the native
agent service boundary. Chromium commit `ad736125ee` fixes all three and adds
browser-test coverage.

## Fixes

- CR-01: `list_windows` now returns only windows from the initiating browser's
  profile, and explicit cross-profile `window_session_id` targets return
  `TAB_OUT_OF_SCOPE`.
- CR-02: generic `open_tab` and `navigate` routes now allow only HTTP, HTTPS,
  and `about:blank` URLs; `javascript:`, `data:`, `file:`, and arbitrary
  `chrome://` routes return `PERMISSION_BLOCKED`.
- WR-01: `open_prometheus_new_tab` and `open_prometheus_control_panel` now claim
  the created tabs for the issuing session before returning success.

## Verification

- `../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests` - passed.
- `./out/Default/browser_tests --gtest_filter='*PrometheusAgentServiceBrowserTest.ListWindowsAndExplicitTargetsStayWithinProfile:*PrometheusAgentServiceBrowserTest.NavigationRoutesRejectUnsafeSchemes:*PrometheusAgentInternalSurfaceBrowserTest.NewTabAndControlPanelRoutesOpenExpectedWebUIHosts'` - passed, 3/3 tests.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgent*:*PrometheusTabState*'` - passed, 25/25 tests.
- `./out/Default/browser_tests --gtest_filter='*PrometheusAgent*:*PrometheusTabCommands*'` - passed, 13/13 tests.
- `git -C .context/chromium/src diff --check && git diff --check` - passed.

## Result

All code-review findings are fixed and included in exported patch
`0006-fix-17-review-harden-Prometheus-agent-route-boundari.patch`.
