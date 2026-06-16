---
phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
plan: "06"
subsystem: ui
tags: [qt-widgets, tab-management, navigationbar, mainmenu, tabsearchpopup]

requires:
  - phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
    provides: "Compact NavigationBar integration from 07-04"
  - phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
    provides: "TabSearchPopup overview/search/quick-switch foundation from 07-05"
provides:
  - "BrowserWindow slots for Tab Overview, Search Tabs, and MRU-backed quick switch popups"
  - "Native File and compact super-menu actions for tab management surfaces"
  - "NavigationBar icon-only Tab Overview and Search Tabs controls in compact and separate layouts"
affects: [phase-07-tab-management, compact-chrome, navigationbar, mainmenu]

tech-stack:
  added: []
  patterns:
    - "BrowserWindow owns transient TabSearchPopup instances parented to the window and anchored below NavigationBar."
    - "Compact chrome keeps Search Tabs outside the compact tab strip overflow path through a fixed NavigationBar layout ID."

key-files:
  created:
    - .planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-06-SUMMARY.md
  modified:
    - falkon/src/lib/app/browserwindow.h
    - falkon/src/lib/app/browserwindow.cpp
    - falkon/src/lib/app/mainmenu.h
    - falkon/src/lib/app/mainmenu.cpp
    - falkon/src/lib/navigation/navigationbar.h
    - falkon/src/lib/navigation/navigationbar.cpp

key-decisions:
  - "Use BrowserWindow-owned one-shot TabSearchPopup instances with delete-on-close instead of long-lived shared popup state."
  - "Expose quick switch through a native File menu action with unused Ctrl+Shift+A metadata while preserving existing tab and location shortcuts."
  - "Place Tab Overview and Search Tabs after the active address/search field so compact tab overflow cannot hide Search Tabs."

patterns-established:
  - "Tab-management chrome actions route through BrowserWindow slots, then reuse TabSearchPopup modes and existing TabModel/TabMruModel sources."
  - "Subrepo task commits touching files with pre-existing dirty hunks require isolating task hunks before running commit-to-subrepo."

requirements-completed: [UX-03, UX-05]

duration: 7min
completed: 2026-06-16
---

# Phase 07 Plan 06: Native Tab Management Entry Points Summary

**Native menu and toolbar entry points now open model-backed Tab Overview, Search Tabs, and MRU quick-switch popups**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-16T19:54:02Z
- **Completed:** 2026-06-16T20:01:00Z
- **Tasks:** 2
- **Files modified:** 6 source files plus this summary

## Accomplishments

- Added `BrowserWindow::showTabOverview()`, `showTabSearch()`, and `showQuickSwitch()` slots that instantiate real `TabSearchPopup` modes.
- Added native File menu and compact super-menu actions for `Tab Overview`, `Search Tabs`, and quick switch.
- Added an unused `Ctrl+Shift+A` shortcut for quick switch without remapping existing tab or location shortcuts.
- Added icon-only `NavigationBar` buttons for `Tab Overview` and `Search Tabs` with exact tooltips and accessible names.
- Kept `Search Tabs` in the compact fixed chrome layout outside the compact tab strip overflow path.

## Task Commits

Each task was committed atomically in the `falkon` sub-repo:

1. **Task 1: Add BrowserWindow popup entry points and menu actions** - `f1f3f8e35` (feat)
2. **Task 2: Add toolbar access for compact and separate layouts** - `7da2559db` (feat)

## Task Acceptance Verification

| Task | Criterion | Verification | Result |
|------|-----------|--------------|--------|
| 1 | BrowserWindow exposes slots for all three popup modes. | `rg "showTabOverview|showTabSearch|showQuickSwitch|TabSearchPopup|tabMruModel" falkon/src/lib/app/browserwindow.h falkon/src/lib/app/browserwindow.cpp` found all slots, popup construction, and quick-switch mode. | PASS |
| 1 | Menu actions open real `TabSearchPopup` instances. | `rg "Tab Overview|Search Tabs|QuickSwitchTabs|showQuickSwitch" falkon/src/lib/app/mainmenu.cpp falkon/src/lib/app/browserwindow.cpp` found File/super-menu actions routed to BrowserWindow slots and `TabSearchPopup::QuickSwitchMode`. | PASS |
| 1 | Existing tab and location shortcuts are not removed or remapped. | `rg -n "Ctrl\\+T|Ctrl\\+W|Ctrl\\+Shift\\+T|Ctrl\\+L|Alt\\+D|Ctrl\\+Tab|Ctrl\\+Shift\\+A" falkon/src/lib/app/browserwindow.cpp falkon/src/lib/app/mainmenu.cpp falkon/src/lib/tabwidget` showed existing shortcuts intact and only new `Ctrl+Shift+A`. | PASS |
| 2 | Toolbar has reachable overview and search controls. | `rg "button-taboverview|button-searchtabs|showTabOverview|showTabSearch" falkon/src/lib/navigation/navigationbar.*` found both buttons registered and connected to BrowserWindow slots. | PASS |
| 2 | Compact overflow does not hide Search Tabs. | `rg -n "compact-tabs|button-searchtabs|button-tools" falkon/src/lib/navigation/navigationbar.cpp` showed fixed compact layout IDs place `button-searchtabs` after `locationbar`, outside `compact-tabs`. | PASS |
| 2 | Tooltips/accessibility labels match the UI spec copy. | `rg -n "setToolTip\\(tr\\(\"Tab Overview\"\\)|setToolTip\\(tr\\(\"Search Tabs\"\\)|setAccessibleName\\(tr\\(\"Tab Overview\"\\)|setAccessibleName\\(tr\\(\"Search Tabs\"\\)" falkon/src/lib/navigation/navigationbar.cpp` found exact strings. | PASS |

## Verification

- `git diff --check`: PASS
- `git -C falkon diff --check`: PASS
- `rg "Tab Overview|Search Tabs|showQuickSwitch|TabSearchPopup" falkon/src/lib/navigation falkon/src/lib/app`: PASS
- `if test -d falkon/build; then cmake --build falkon/build --target help; fi`: failed because `falkon/build` is a parent directory without `CMakeCache.txt`.
- `cmake --build falkon/build/fsb-baseline --target help`: PASS
- `cmake --build falkon/build/fsb-baseline --target FalkonPrivate -j2`: PASS; emitted pre-existing Qt deprecation/style warnings and linker flag warnings outside this change.

## Files Created/Modified

- `falkon/src/lib/app/browserwindow.h` - Declares BrowserWindow tab overview, search, and quick-switch slots.
- `falkon/src/lib/app/browserwindow.cpp` - Creates window-parented `TabSearchPopup` instances anchored below NavigationBar and routes slots to overview/search/quick-switch modes.
- `falkon/src/lib/app/mainmenu.h` - Declares MainMenu wrappers for the new BrowserWindow slots.
- `falkon/src/lib/app/mainmenu.cpp` - Adds File and compact super-menu actions for tab overview/search/quick switch.
- `falkon/src/lib/navigation/navigationbar.h` - Stores native tab overview/search toolbar buttons.
- `falkon/src/lib/navigation/navigationbar.cpp` - Adds icon-only toolbar buttons, exact labels, and compact/separate layout IDs.
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-06-SUMMARY.md` - Captures execution results.

## Decisions Made

- Used transient BrowserWindow-owned popups with `Qt::WA_DeleteOnClose` so popup lifetime follows the window and Esc handling stays in `TabSearchPopup`.
- Added quick switch as `Quick Switch Tabs` with `Ctrl+Shift+A`, which was unused in the current codebase and leaves existing `Ctrl+Tab` tab cycling untouched.
- Registered overview/search buttons in both compact fixed layout and separate default layout, while keeping them available through toolbar configuration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `browserwindow.cpp` and `mainmenu.cpp` had unrelated pre-existing dirty hunks. Task 1 temporarily isolated only this plan's hunks before running `commit-to-subrepo`, then restored the pre-existing dirty hunks afterward.
- The literal `falkon/build` CMake help command failed because the configured tree is `falkon/build/fsb-baseline`; the configured help target and focused `FalkonPrivate` build passed.

## Known Stubs

None - no placeholder UI, mock data, or hardcoded empty rendering paths were introduced. Stub scan matches were existing pointer defaults and default arguments, not UI stubs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 07-07 can add persistent native tab group metadata now that overview/search/quick-switch surfaces are reachable from menus and compact chrome.

## Self-Check: PASSED

- Verified all created/modified source and summary files exist.
- Verified task commits `f1f3f8e35` and `7da2559db` exist in the `falkon` sub-repo history.

---
*Phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem*
*Completed: 2026-06-16*
