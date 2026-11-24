---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 02
subsystem: ui
tags: [chromium, views, layout, compact-chrome, prometheus]
requires:
  - phase: 15
    plan: 01
    provides: Prometheus compact/separate chrome mode pref helper
provides:
  - Compact chrome layout allocation helper
  - Compact-mode BrowserView tab-strip/top-container layout gate
  - Browser test coverage for separate and compact layout branches
affects: [phase-15, chromium-ui, compact-chrome]
tech-stack:
  added: []
  patterns:
    - Chromium Views layout changes gated by a typed Prometheus PrefService helper
key-files:
  created:
    - .context/chromium/src/chrome/browser/ui/views/frame/prometheus_compact_chrome_layout.h
    - .context/chromium/src/chrome/browser/ui/views/frame/prometheus_compact_chrome_layout.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_compact_chrome_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/ui/views/frame/layout/browser_view_tabbed_layout_impl.cc
    - .context/chromium/src/chrome/browser/ui/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
key-decisions:
  - "Compact chrome remains gated by `PrometheusChromeMode::kCompact`; separate/default mode leaves Chromium layout behavior unchanged."
  - "The compact reservation is idempotent so both normal BrowserView and top-container layout paths can apply it safely."
patterns-established:
  - "Prometheus Views layout additions should live beside existing Chromium layout owners and be gated by typed prefs, not by replacing BrowserView or native frame behavior."
requirements-completed: [UX-01, UX-02, UX-06, UX-07]
duration: 16min
completed: 2026-07-07
---

# Phase 15 Plan 02: Compact Chrome Layout Summary

**Compact-mode Views layout path with separate-mode fallback and browser-test coverage**

## Performance

- **Duration:** 16 min
- **Started:** 2026-07-07T05:31:00Z
- **Completed:** 2026-07-07T05:47:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `prometheus_compact_chrome_layout.{h,cc}` with compact chrome height, minimum location width, and reserved control width allocation.
- Wired compact mode into Chromium's current tabbed Views layout path using `GetPrometheusChromeMode(*profile->GetPrefs())`.
- Preserved separate/default behavior as the unchanged Chromium layout path.
- Added browser tests that exercise separate mode and compact mode at an 800px window width with enough tabs to stress compression while keeping Search Tabs reachable.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add compact chrome layout helper and gate** - `007c5620d2`
2. **Task 1 follow-up: Apply gate to normal tabstrip layout path** - `0e0082e987`
3. **Task 2: Add compact layout browser tests** - `1eb1bf6c9e`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/ui/views/frame/prometheus_compact_chrome_layout.h` - Defines compact chrome height, minimum location width, and allocation API.
- `.context/chromium/src/chrome/browser/ui/views/frame/prometheus_compact_chrome_layout.cc` - Implements reserved width calculation for navigation, tab search, side panel, and menu controls.
- `.context/chromium/src/chrome/browser/ui/views/frame/layout/browser_view_tabbed_layout_impl.cc` - Applies compact-mode reservation and 50px height guard on the normal BrowserView path and top-container path.
- `.context/chromium/src/chrome/browser/ui/BUILD.gn` - Adds the compact layout helper sources and Prometheus pref helper dependency.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_compact_chrome_browsertest.cc` - Covers compact and separate layout reachability.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Adds the compact layout browser test to the Prometheus browser test target.

## Decisions Made

- Kept compact mode opt-in behind the existing Phase 15-01 pref helper instead of introducing a second feature flag.
- Applied the compact reservation in both normal `BrowserView` tab-strip layout and `top_container` layout because macOS browser tests exercise the normal `BrowserView` parent path.
- Deferred Prometheus side-panel toggle assertions to 15-03 because that control is introduced by the next plan.

## Deviations from Plan

- The plan referenced stale files under `chrome/browser/ui/views/frame/browser_view_layout.{h,cc}` and `chrome/browser/ui/views/frame/BUILD.gn`. The active checkout uses `chrome/browser/ui/views/frame/layout/browser_view_tabbed_layout_impl.cc` and `chrome/browser/ui/BUILD.gn` for this layout boundary.
- Task 2 asserts Search Tabs reachability and compact/separate branch behavior. The Prometheus side-panel toggle visibility assertion is intentionally deferred to 15-03, where the toggle is created.

## Issues Encountered

- The first compact browser test run showed that only the top-container branch enforced the 50px compact height. Added the same compact-mode gate to the normal BrowserView tab-strip layout path, then reran the browser tests successfully.

## Verification

- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default chrome` - passed.
- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default browser_tests` - passed.
- `./out/Default/browser_tests --gtest_filter='PrometheusCompactChromeLayoutBrowserTest.*'` - passed, 2/2 tests.
- `git -C .context/chromium/src diff --check` - passed.
- Acceptance marker scan confirmed `PrometheusChromeMode::kCompact`, `kPrometheusCompactChromeHeight`, `kPrometheusCompactMinLocationWidth`, compact reservation calls, separate-mode test, compact-mode test, and the 800px resize path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-03 can add the Prometheus side-panel/FSB toolbar controls on top of the compact layout reservation without changing the mode pref contract.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
