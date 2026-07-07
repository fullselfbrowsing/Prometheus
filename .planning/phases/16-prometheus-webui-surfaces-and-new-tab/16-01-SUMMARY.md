---
phase: 16-prometheus-webui-surfaces-and-new-tab
plan: 01
subsystem: ui
tags: [chromium, webui, grit, browser-tests, prometheus]
requires:
  - phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
    provides: Prometheus Chromium shell and browser-test wiring
provides:
  - Production Prometheus WebUI config/controller classes for new tab, side panel, and control panel
  - Packaged Phase 16 static HTML/CSS/JS resources in the Prometheus GRIT resource bundle
  - Browser-test coverage proving each Prometheus host creates the expected WebUI controller and renders required copy
affects: [phase-16, phase-17, phase-20, prometheus-webui]
tech-stack:
  added: []
  patterns:
    - Chromium `DefaultWebUIConfig` plus `WebUIDataSource` hosts backed by packaged GRIT resources
key-files:
  created:
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_newtab.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
  modified:
    - .context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc
    - .context/chromium/src/chrome/common/webui_url_constants.h
    - .context/chromium/src/chrome/common/webui_url_constants.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
key-decisions:
  - "Registered production Phase 16 WebUI configs unguarded; the Phase 14 preview remains the only DCHECK/UNKNOWN gated Prometheus surface."
  - "Kept the first resource shell static and browser-owned, with no remote resources or prompt/secrets logging."
patterns-established:
  - "Future Prometheus WebUI surfaces should share explicit `WebUIDataSource` resource mappings and browser tests that assert concrete controller types."
requirements-completed: [WEBUI-01, WEBUI-05, WEBUI-06]
duration: 18min
completed: 2026-07-07
---

# Phase 16 Plan 01: WebUI Foundation Summary

**Production Prometheus WebUI hosts for new tab, side panel, and control panel backed by packaged Chromium resources**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-07T06:51:19Z
- **Completed:** 2026-07-07T07:09:22Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Added `PrometheusNewTabUI`, `PrometheusSidePanelUI`, and `PrometheusControlPanelUI` with matching `DefaultWebUIConfig` classes.
- Registered `chrome://prometheus-newtab/`, `chrome://prometheus-side-panel/`, and `chrome://prometheus-control-panel/` as production WebUI hosts.
- Added packaged static HTML/CSS/JS resources for the three Phase 16 surfaces through `prometheus_resources.grdp`.
- Added browser tests that navigate to every host, verify the concrete controller type, and assert required UI copy/placeholder state.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add Prometheus WebUI hosts and controllers** - `33ea0c1453`
2. **Task 2: Package minimal resources and foundation tests** - `e3765b3085`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h` - Declares the three production Prometheus WebUI configs/controllers.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc` - Registers per-host `WebUIDataSource` instances and resource paths.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_newtab.html` - Minimal new-tab/start surface.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html` - Minimal four-mode side-panel surface.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html` - Minimal nine-section control-panel shell.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css` - Shared Phase 16 WebUI styling.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js` - Minimal ready marker for the static surfaces.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc` - Browser tests for host/controller/content coverage.
- `.context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc` - Registers production Prometheus configs while leaving preview gating intact.
- `.context/chromium/src/chrome/common/webui_url_constants.*` - Adds host and URL constants plus chrome URL host listing.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp` - Adds Phase 16 resource IDs.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn` and `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Wire production sources and browser-test coverage.

## Decisions Made

- Used separate production hosts for the three surfaces to preserve clear entry semantics and test isolation.
- Kept Phase 16 resources self-contained: no remote CSS, fonts, scripts, images, prompt URL transport, console logging, or secret fixtures.
- Included Prometheus hosts in `ChromeURLHosts()` so built-in chrome URL discovery recognizes them.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first browser-test run crashed because the helper used `content::JsReplace` incorrectly and because the placeholder check used `innerText`. Fixed the helper to use `content::JsReplace("...$1...", text)` and added a dedicated placeholder attribute assertion. The rerun passed.

## Verification

- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default chrome browser_tests` - passed.
- `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests` - passed after the test-helper edit.
- `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusWebUIFoundation*'` - passed, 3/3 tests.
- `cd .context/chromium/src && git diff --check` - passed.
- Static scan for remote resources, prompt/secret logging, and obvious secret strings in Phase 16 HTML/CSS/JS - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 16-02 can expand `chrome://prometheus-newtab/` and add the safe Ask FSB browser-process handoff on top of the production host and packaged resource path created here.

---
*Phase: 16-prometheus-webui-surfaces-and-new-tab*
*Completed: 2026-07-07*
