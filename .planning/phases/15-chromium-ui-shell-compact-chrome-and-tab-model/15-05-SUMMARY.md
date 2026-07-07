---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 05
subsystem: ui
tags: [chromium, tabs, commands, tab-search, prometheus]
requires:
  - phase: 15
    plan: 02
    provides: Compact chrome layout allocation helper
  - phase: 15
    plan: 03
    provides: Native side-panel and Ask FSB toolbar entry points
provides:
  - Prometheus tab command adapter
  - Browser coverage for native tab command delegation
  - Compact-mode tab-search bubble reachability coverage
affects: [phase-15, chromium-ui, tabs]
tech-stack:
  added: []
  patterns:
    - Delegate advanced tab actions to Chromium browser commands and TabStripModel context-menu commands
    - Test compact tab-search reachability through BrowserView's TabSearchBubbleHost
key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
key-decisions:
  - "Prometheus tab commands delegate to Chromium-native commands instead of detaching or mutating WebContents manually."
  - "Unsupported unload/discard returns false with no mutation until a supported Chromium tab-discard path is selected."
  - "Compact tab-search reachability is covered through existing BrowserView/TabSearchBubbleHost APIs without adding parallel tab-search wiring."
patterns-established:
  - "Prometheus browser tests can live in chrome/browser/prometheus while being wired into the existing chrome/browser/ui/views/prometheus browser_tests target."
requirements-completed: [UX-03, UX-04, UX-05]
duration: 10min
completed: 2026-07-07
---

# Phase 15 Plan 05: Tab Commands and Tab Search Summary

**Chromium-native advanced tab command adapter plus compact tab-search coverage**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-07T06:14:00Z
- **Completed:** 2026-07-07T06:23:58Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `PrometheusTabCommand` and `ExecutePrometheusTabCommand(BrowserWindowInterface*, PrometheusTabCommand, int)`.
- Delegated duplicate and move-to-new-window to Chromium browser command helpers.
- Delegated close, close-others, close-to-right, add-to-new-group, pin, and site mute to `TabStripModel::ExecuteContextMenuCommand`.
- Kept unload/discard unsupported for now by returning `false` without mutating the tab strip.
- Added browser tests for duplicate, move-to-new-window, add-to-new-group, unsupported unload/discard, and compact tab-search bubble reachability.
- Wired the Prometheus command tests into the existing Prometheus browser test source set.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add Prometheus tab command adapter** - `a5f864171c`
2. **Task 2: Add browser tests for tab commands and search reachability** - `a4423116ff`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.h` - Declares the Prometheus tab command enum and adapter API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.cc` - Implements native browser-command and `TabStripModel` delegation.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Adds the command adapter source set.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands_browsertest.cc` - Covers tab command behavior and compact tab-search bubble reachability.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Adds the new browser test source and direct dependencies.

## Decisions Made

- Used `chrome::DuplicateTabAt`, `chrome::MoveTabsToNewWindow`, and `TabStripModel` context-menu commands as the command surface.
- Returned `false` for unload/discard rather than introducing a bespoke discard implementation.
- Used `ui_test_utils::BrowserCreatedObserver` for move-to-new-window coverage, matching Chromium's native tab-strip tests.
- Verified compact tab search through `BrowserView::GetTabSearchBubbleHost()` and `WebUIBubbleManager`, because the compact toolbar already owns the tab-search button path.

## Deviations from Plan

- The plan listed `chrome/browser/ui/views/tab_search_bubble_host.cc` and `chrome/browser/ui/views/tabs/browser_tab_strip_controller.cc` as modified files, but no source changes were needed there. Existing Chromium Views tab-search APIs were sufficient.
- The browser test file lives in `chrome/browser/prometheus/` as planned, but is wired through `chrome/browser/ui/views/prometheus/BUILD.gn` because that is the existing Prometheus browser test target included by `browser_tests`.

## Issues Encountered

- `autoninja` was not on PATH in the resumed shell. Verification used the checkout-local depot_tools path: `../../depot_tools/autoninja`.

## Verification

- `../../depot_tools/autoninja -C out/Default chrome/browser/prometheus:prometheus_tab_commands` - passed.
- `../../depot_tools/autoninja -C out/Default browser_tests` - passed.
- `./out/Default/browser_tests --gtest_filter='*PrometheusTabCommands*:*Prometheus*TabSearch*'` - passed, 6/6 tests.
- `../../depot_tools/autoninja -C out/Default chrome browser_tests` - passed, no work remaining.
- `git -C .context/chromium/src diff --check` - passed.
- Acceptance marker scan confirmed `DuplicateIncreasesTabCount`, `AddToNewGroupCreatesGroup`, `UnsupportedUnloadReturnsFalse`, `ExecutePrometheusTabCommand`, `DuplicateTab`, and `ExecuteContextMenuCommand`.

## User Setup Required

None.

## Next Phase Readiness

Plan 15-06 can run the full shell test gate and export Phase 15 patches with the tab command adapter and browser coverage in place.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
