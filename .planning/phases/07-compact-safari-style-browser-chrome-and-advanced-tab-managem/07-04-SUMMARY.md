---
phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
plan: "04"
subsystem: ui
tags: [qt-widgets, compact-chrome, navigationbar, tabwidget, tabs]

requires:
  - phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
    provides: "Persisted compact/separate tab layout settings from 07-01"
  - phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
    provides: "Agent-aware tab roles from 07-02"
  - phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
    provides: "CompactTabStrip primitive from 07-03"
provides:
  - "Compact NavigationBar composition with CompactTabStrip and existing LocationBar stack in one row"
  - "Runtime compact/separate layout switching from qzSettings->tabLayout"
  - "Traditional TabBar row hiding in compact layout while preserving separate layout behavior"
affects: [phase-07-compact-chrome, navigationbar, tabwidget, compact-tab-strip]

tech-stack:
  added: []
  patterns:
    - "NavigationBar chooses compact composition from canonical QzSettings tabLayout and keeps separate mode on saved toolbar layout IDs."
    - "TabWidget hides the conventional TabBar through TabBar::setForceHidden() while preserving tab contents and LocationBar ownership."

key-files:
  created:
    - .planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-04-SUMMARY.md
  modified:
    - falkon/src/lib/navigation/navigationbar.h
    - falkon/src/lib/navigation/navigationbar.cpp
    - falkon/src/lib/tabwidget/tabwidget.h
    - falkon/src/lib/tabwidget/tabwidget.cpp

key-decisions:
  - "Use a fixed compact NavigationBar row from qzSettings->tabLayout while preserving saved NavigationBar/Layout and ShowSearchBar behavior for Separate."
  - "Hide the conventional tab row with TabBar::setForceHidden() instead of moving tab ownership or LocationBar synchronization out of TabWidget."

patterns-established:
  - "Compact chrome reuses TabWidget::locationBars() as the active unified address/search field."
  - "Compact/separate runtime reloads flow through MainApplication::settingsReloaded for NavigationBar and TabWidget."

requirements-completed: [UX-01, UX-02, UX-05]

duration: 5min
completed: 2026-06-16
---

# Phase 07 Plan 04: Compact Chrome Integration Summary

**Compact toolbar chrome now hosts inactive tabs beside the current tab's existing LocationBar, while Separate keeps the conventional tab bar path**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-16T19:31:53Z
- **Completed:** 2026-06-16T19:37:09Z
- **Tasks:** 2
- **Files modified:** 4 source files plus this summary

## Accomplishments

- Instantiated `CompactTabStrip` in `NavigationBar` and registered it as toolbar widget ID `compact-tabs`.
- Added compact-mode `NavigationBar` composition: back/forward, reload/stop, add-tab, compact strip, existing `TabWidget::locationBars()` stack, super menu, and tools menu.
- Hid the standalone `WebSearchBar` in compact mode while preserving saved `ShowSearchBar` behavior in Separate.
- Hid only the conventional `TabBar` row in compact mode through `TabBar::setForceHidden()`, leaving tab contents and `m_locationBars` synchronization unchanged.

## Task Commits

Each task was committed atomically in the `falkon` sub-repo:

1. **Task 1: Add compact row composition to NavigationBar** - `f25c6afe6` (feat)
2. **Task 2: Switch traditional tab bar visibility by layout** - `46cbbf0af` (feat)

## Task Acceptance Verification

| Task | Criterion | Verification | Result |
|------|-----------|--------------|--------|
| 1 | Compact mode puts compact tabs and the existing location bar stack in the same toolbar row. | `rg -n "CompactTabStrip|compact-tabs|locationBars" falkon/src/lib/navigation/navigationbar.*` found the strip member, `compact-tabs` registration/layout ID, and `m_window->tabWidget()->locationBars()` inside `m_navigationSplitter`. | PASS |
| 1 | Separate mode follows the existing `NavigationBar::loadSettings()` layout path. | `rg -n "NavigationBar|ShowSearchBar|defaultIds|locationbar" falkon/src/lib/navigation/navigationbar.cpp` showed separate mode still reads saved `NavigationBar/Layout`, `ShowSearchBar`, de-duplicates IDs, and ensures `locationbar`. | PASS |
| 1 | Compact mode does not create a second URL/search parser or input. | The compact path reuses `m_navigationSplitter` and `TabWidget::locationBars()`; no new `LocationBar::loadAction`, completion, or URL/search parsing code was added. | PASS |
| 2 | Compact hides only the conventional tab bar, not tab contents or location bars. | `rg -n "tabLayout|setForceHidden|locationBars" falkon/src/lib/tabwidget/tabwidget.*` found only `m_tabBar->setForceHidden(m_compactLayout)` added, with existing `m_locationBars` add/remove/current-widget paths unchanged. | PASS |
| 2 | Separate keeps existing tab bar behavior, add-tab behavior, overflow behavior, and closed-tabs button behavior. | `TabWidget::loadSettings()` still calls `m_tabBar->loadSettings()` and `updateClosedTabsButton()`; add-tab, overflow, and closed-tabs code paths were not modified. | PASS |
| 2 | Existing open-location shortcuts still focus and select the current LocationBar. | `rg -n "OpenLocation|Alt\\+D|Key_OpenUrl|locationBar\\(\\)->setFocus|locationBar\\(\\)->selectAll|locationBars\\(\\)->currentWidget" falkon/src/lib/app/browserwindow.cpp falkon/src/lib/app/mainmenu.cpp` confirmed `Ctrl+L`, `Alt+D`, File > Open Location, and `Qt::Key_OpenUrl` still route to `BrowserWindow::openLocation()`. | PASS |

## Verification

- `git diff --check`: PASS
- `git -C falkon diff --check HEAD~2..HEAD`: PASS
- `rg "CompactTabStrip|compact-tabs|tabLayout|locationBars|isCompactLayout" falkon/src/lib/navigation falkon/src/lib/tabwidget`: PASS
- `cmake --build falkon/build --target help`: failed because `falkon/build` is a parent directory without `CMakeCache.txt`.
- `cmake --build falkon/build/fsb-baseline --target help`: PASS
- `cmake --build falkon/build/fsb-baseline --target FalkonPrivate -j2`: PASS; compile warnings were pre-existing Qt deprecations/style warnings outside this change.

## Files Created/Modified

- `falkon/src/lib/navigation/navigationbar.h` - Added the compact strip member, compact layout state, and compact constraint helper declaration.
- `falkon/src/lib/navigation/navigationbar.cpp` - Registered `CompactTabStrip`, added compact row composition, hid standalone search in compact mode, reused `TabWidget::locationBars()`, and applied compact width/height constraints.
- `falkon/src/lib/tabwidget/tabwidget.h` - Added `isCompactLayout()` and cached compact layout state.
- `falkon/src/lib/tabwidget/tabwidget.cpp` - Hid the conventional `TabBar` row in compact mode via `setForceHidden()` while preserving existing `loadSettings()` tab behavior.
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-04-SUMMARY.md` - Captured execution results.

## Decisions Made

- Used a fixed compact toolbar row from canonical `qzSettings->tabLayout` so compact mode is deterministic and does not depend on a user-customized separate toolbar layout.
- Kept separate mode on the existing configurable `NavigationBar/Layout` and `ShowSearchBar` path for compatibility.
- Used `TabBar::setForceHidden()` for compact mode instead of moving tab contents, tab ownership, or LocationBar synchronization out of `TabWidget`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The literal plan verification command `cmake --build falkon/build --target help` still fails because the configured CMake tree is nested at `falkon/build/fsb-baseline`. The configured tree help target and `FalkonPrivate` build both passed.
- The focused build emitted pre-existing Qt deprecation/style warnings in unrelated files.

## Known Stubs

None - the source changes did not introduce placeholder UI, mock data, or hardcoded empty values that flow to rendering.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 07-05 can build tab overview/search and quick-switch surfaces against the compact chrome now that the toolbar row hosts inactive tabs and the active tab remains the existing `LocationBar`.

## Self-Check: PASSED

- Verified all created/modified source and summary files exist.
- Verified task commits `f25c6afe6` and `46cbbf0af` exist in the `falkon` sub-repo history.

---
*Phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem*
*Completed: 2026-06-16*
