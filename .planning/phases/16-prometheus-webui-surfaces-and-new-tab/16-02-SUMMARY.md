---
phase: 16-prometheus-webui-surfaces-and-new-tab
plan: 02
subsystem: ui
tags: [chromium, webui, side-panel, prompt-handoff, prometheus]
requires:
  - phase: 16-prometheus-webui-surfaces-and-new-tab
    plan: 01
    provides: Production Prometheus WebUI hosts and packaged resources
provides:
  - Start page UI with Prometheus brand row, Ask FSB form, favorites, and suggested automations
  - Profile-owned Ask FSB handoff state with prompt trimming and bounded storage
  - Shared Prometheus side-panel helper used by toolbar and WebUI handoff paths
  - Browser-test coverage proving the sample prompt stays out of URL/history and reaches side-panel seed state
affects: [phase-16, phase-17, phase-20, prometheus-webui]
tech-stack:
  added: []
  patterns:
    - Chromium `content::WebUIMessageHandler` bridge for start-page to browser-process handoff
    - Profile `SupportsUserData` storage for renderer-originated pending prompt state
key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.h
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.cc
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_newtab.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/toolbar/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn
key-decisions:
  - "Keep Ask FSB prompt transport entirely out of URLs by storing bounded pending state on the browser profile."
  - "Share one Prometheus side-panel entry helper between toolbar and WebUI handoff instead of keeping a toolbar-only placeholder."
  - "Use the packaged `chrome://prometheus-side-panel/` WebUI inside the side-panel entry so Plan 16-03 can extend the real surface."
patterns-established:
  - "Start-page WebUI handlers should sanitize renderer input, store only bounded browser-owned state, and expose seed state through side-panel WebUI messages."
requirements-completed: [WEBUI-01, WEBUI-02, WEBUI-03, WEBUI-06]
duration: 22min
completed: 2026-07-07
---

# Phase 16 Plan 02: Start Page and Ask FSB Handoff Summary

**Prometheus start page UI plus safe browser-process Ask FSB handoff without prompt URL leakage**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-07T07:09:22Z
- **Completed:** 2026-07-07T07:31:39Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Expanded `chrome://prometheus-newtab/` into an operational start page with PM/Prometheus/Powered by FSB branding, `Search or ask FSB`, `Ask FSB`, favorites, and suggested automations.
- Added `prometheus::SetPendingAskFsbPrompt()` and related helpers to keep renderer-originated prompts in browser-owned profile state with trimming and a 4096-byte bound.
- Added WebUI message handlers for `prometheusAskFsb` and `prometheusRequestAskFsbSeed`.
- Replaced the toolbar-only empty side-panel placeholder with a shared helper that registers a Prometheus side-panel entry loading `chrome://prometheus-side-panel/`.
- Added a browser test that submits `book me a flight to Tokyo`, verifies the active/visible URLs do not contain the prompt, and confirms the side-panel WebUI receives the prompt through browser-owned state.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Implement start page UI** - `4be2b60315`
2. **Task 2: Add browser-process Ask FSB handoff state** - `5ed0bd5f42`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_ask_fsb_handoff.*` - Profile-owned bounded pending prompt state.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.*` - Shared side-panel entry registration/show/toggle helper.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_newtab.html` - Start-page structure and stable Ask FSB form IDs.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html` - Pending handoff seed container.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css` - Token-named start-page and handoff seed styling.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js` - New-tab submit behavior and side-panel seed hydration.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc` - WebUI message handlers and side-panel show handoff.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc` - URL-leak and side-panel seed regression coverage.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.cc` - Toolbar delegates side-panel behavior to the shared Prometheus helper.
- Related `BUILD.gn` files - Wire new handoff, side-panel helper, and tests.

## Decisions Made

- Stored the pending Ask FSB prompt on `Profile` user data rather than a URL query, renderer global, or static process map.
- Kept the handoff as seed state only. It opens/focuses Prometheus side panel but does not start any real agent task.
- Used `BrowserWindowInterface` in the shared side-panel helper to avoid a GN dependency cycle through `//chrome/browser/ui`.
- Disabled `InitialWebUI` and `WebUIToolbarProcessOverheadExperiment` only inside the Prometheus WebUI browser-test fixture to avoid unrelated top-chrome paint waits.

## Deviations from Plan

- Pulled minimal side-panel WebUI hosting forward from Plan 16-03 so the Ask FSB handoff can open actual Prometheus side-panel content now. Plan 16-03 can focus on richer four-mode behavior and side-panel visibility tests.

## Issues Encountered

- Initial side-panel helper wiring created a GN cycle through `//chrome/browser/ui`; fixed by taking `BrowserWindowInterface*` and depending only on browser-window and side-panel interfaces.
- The first focused browser-test run timed out in Chromium's WebUI toolbar startup paint wait before the test body. The Prometheus WebUI fixture now disables the unrelated Initial WebUI toolbar features for these tests.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests` - passed.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusNewTab*'` - passed, 1/1 test.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*'` - passed, 3/3 tests.
- `cd .context/chromium/src && git diff --check` - passed.
- Static scan of changed Prometheus WebUI/handoff files for remote URLs, console logging, obvious secret strings, and negative letter spacing - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 16-03 can extend the now-WebUI-backed Prometheus side-panel entry with complete FSB Agent, Explorer, Tabs, and Tools mode behavior and side-panel visibility assertions.

---
*Phase: 16-prometheus-webui-surfaces-and-new-tab*
*Completed: 2026-07-07*
