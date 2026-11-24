---
phase: 16-prometheus-webui-surfaces-and-new-tab
plan: 03
subsystem: ui
tags: [chromium, webui, side-panel, toolbar, prometheus]
requires:
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 01
    provides: Production Prometheus WebUI hosts and packaged resources
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 02
    provides: WebUI-backed Prometheus side-panel entry and Ask FSB handoff
provides:
  - Four-mode Prometheus side-panel shell with FSB Agent, Explorer, Tabs, and Tools modes
  - Icon-only side-panel mode controls with local packaged Font Awesome SVG masks, titles, and aria labels
  - Toolbar browser-test coverage proving the side-panel button opens live Prometheus WebUI content
affects: [phase-16, phase-17, phase-20, prometheus-webui]
tech-stack:
  added: []
  patterns:
    - Mode-gated WebUI panels using stable data attributes and aria metadata
    - BrowserView side-panel content-parent inspection for live WebView regression coverage
key-files:
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_toolbar_entrypoint_browsertest.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
key-decisions:
  - "Use icon-only mode buttons with title and aria-label metadata while keeping each mode label in DOM panel content."
  - "Inspect the live side-panel WebView through BrowserView's side-panel content parent in the toolbar regression test."
patterns-established:
  - "Prometheus side-panel mode panels should use stable `data-mode-target` and `data-mode-panel` attributes for DOM tests and JS behavior."
requirements-completed: [WEBUI-03, WEBUI-05, WEBUI-06]
duration: 15min
completed: 2026-07-07
---

# Phase 16 Plan 03: Side Panel WebUI Summary

**Prometheus four-mode side panel with toolbar-visible WebUI content coverage**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-07T07:33:57Z
- **Completed:** 2026-07-07T07:48:32Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Replaced the simple side-panel body with a four-mode WebUI shell for `FSB Agent`, `Explorer`, `Tabs`, and `Tools`.
- Kept Agent mode visible by default with `Ready` and `Ask FSB to work in this browser.` copy.
- Added safe stub states for Explorer, Tabs, and Tools without provider, secret, or vault fixture values.
- Added icon-only segmented mode controls using local packaged Font Awesome SVGs and explicit `title`/`aria-label` metadata.
- Wired the WebUI data source to serve the side-panel icon assets.
- Added browser-test coverage for DOM labels, active Agent copy, mode button metadata, and toolbar-opened side-panel WebUI content.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Implement four-mode side-panel shell** - `df12d3c576`
2. **Task 2: Cover toolbar side-panel WebUI content** - `a378be0513`

## Files Modified

- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html` - Four-mode side-panel structure and stable mode IDs.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css` - Icon-only segmented controls, mode panels, badges, and stub rows.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js` - Side-panel mode switching and Agent-mode seed activation.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc` - Local SVG icon resource paths.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc` - Side-panel mode shell and icon metadata assertions.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_toolbar_entrypoint_browsertest.cc` - Toolbar-opened live side-panel WebView assertion.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Test dependency for side-panel Views inspection.

## Decisions Made

- Kept the existing `SidePanelEntryId::kAssistant` side-panel entry from Plan 16-02 and extended its WebUI content rather than creating a second Prometheus-specific side-panel entry.
- Used packaged SVG masks for the side-panel mode buttons so no remote icon assets or new binary assets are needed.
- Tested the toolbar-opened side panel by walking the actual `BrowserView::side_panel()` content tree to find the live `views::WebView`.

## Deviations from Plan

- The side-panel was already WebUI-backed from Plan 16-02, so this plan focused on richer four-mode content and toolbar-opened live-content coverage instead of replacing a remaining placeholder.

## Issues Encountered

- The first toolbar test attempt used a cached side-panel entry lookup after Chromium had moved the live view into the side-panel content parent. The test now inspects the actual visible side-panel content tree.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusSidePanel*:*PrometheusToolbarEntryPoint*'` - passed, 2/2 toolbar entry-point tests.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*:*PrometheusNewTab*'` - passed, 4/4 WebUI tests.
- `cd .context/chromium/src && git diff --check` - passed.
- Static scan of changed production WebUI/controller files for remote URLs, console logging, obvious secret strings, and negative letter spacing - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 16-04 can extend the production WebUI control panel shell with operator sections using the same packaged resource and browser-test patterns.

---
*Phase: 16-prometheus-webui-surfaces-and-new-tab*
*Completed: 2026-07-07*
