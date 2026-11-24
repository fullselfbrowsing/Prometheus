---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 03
subsystem: ui
tags: [chromium, views, toolbar, side-panel, prometheus]
requires:
  - phase: 15
    plan: 01
    provides: Prometheus compact/separate chrome mode pref helper
provides:
  - Reusable Prometheus toolbar button helper
  - Native side-panel and Ask FSB toolbar entry points
  - Browser test coverage for toolbar accessibility and renderability
affects: [phase-15, chromium-ui, toolbar, side-panel]
tech-stack:
  added: []
  patterns:
    - Chromium Views toolbar controls backed by Prometheus action icons and color tokens
key-files:
  created:
    - .context/chromium/src/chrome/browser/ui/views/toolbar/prometheus_toolbar_button.h
    - .context/chromium/src/chrome/browser/ui/views/toolbar/prometheus_toolbar_button.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_toolbar_entrypoint_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/ui/views/toolbar/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.h
    - .context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/resources/prometheus/vector_icons/fa_wand_magic_sparkles.icon
key-decisions:
  - "Prometheus toolbar buttons use the Phase 14 `PrometheusAction` resolver and Phase 14 `kColorPrometheus*` token ids instead of ad hoc icon or color assets."
  - "The Phase 15 side-panel stub uses the existing `kAssistant` side-panel entry key because it has a toolbar action id; `kSidePanelDev` would trip the side-panel pinning controller's action-id checks."
  - "Ask FSB is open-only in this phase: it opens the placeholder side panel and does not submit prompts, call providers, or touch runtime state."
patterns-established:
  - "Prometheus toolbar entry points should be native Views controls with exact accessible names and tooltips from the UI spec."
requirements-completed: [UX-04, UX-05, UX-06, UX-07]
duration: 17min
completed: 2026-07-07
---

# Phase 15 Plan 03: Toolbar Entry Points Summary

**Native Prometheus side-panel and Ask FSB toolbar buttons with accessibility and render coverage**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-07T05:48:00Z
- **Completed:** 2026-07-07T06:04:40Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `PrometheusToolbarButton`, a reusable 32px `ToolbarButton` wrapper that resolves Prometheus semantic actions to vector icons.
- Styled normal, hover, pressed, disabled, and active states with Phase 14 Prometheus color ids.
- Wired native toolbar buttons for `Toggle Prometheus side panel` and `Ask FSB`.
- Added a placeholder side-panel entry that opens without loading FSB runtime/provider content.
- Added browser coverage asserting both buttons exist, render, and expose exact accessible names and tooltips.
- Fixed the `fa_wand_magic_sparkles.icon` vector path so the Ask FSB button can rasterize without a vector command crash.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add reusable toolbar button helper** - `c3f7c677f3`
2. **Task 2: Wire side-panel and Ask FSB buttons into ToolbarView** - `fd54a3821b`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/ui/views/toolbar/prometheus_toolbar_button.h` - Declares the reusable Prometheus toolbar button API.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/prometheus_toolbar_button.cc` - Resolves Prometheus action icons and applies Prometheus token colors.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/BUILD.gn` - Adds the toolbar helper sources and dependencies.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.h` - Adds testing accessors, callbacks, and toolbar button members.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.cc` - Creates the two Prometheus buttons and opens/toggles the placeholder side-panel entry.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_toolbar_entrypoint_browsertest.cc` - Covers exact labels, tooltips, visibility, size, and paint-time icon validity.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Adds the toolbar entry-point browser test.
- `.context/chromium/src/chrome/browser/resources/prometheus/vector_icons/fa_wand_magic_sparkles.icon` - Corrects a malformed path command exposed by rendering the Ask FSB icon.

## Decisions Made

- Used `PrometheusAction::kSidebarFlip` for the side-panel button and `PrometheusAction::kWandMagicSparkles` for Ask FSB.
- Used `SidePanelEntry::Id::kAssistant` for the temporary Prometheus side-panel entry because it has a side-panel action id and avoids pinning-controller checks.
- Kept the placeholder side-panel header hidden and disabled ephemeral toolbar pin surfacing so Phase 15 adds only the entry point, not Phase 16/20 content.
- Kept the Ask FSB action open-only to satisfy the Phase 15 threat model without provider/runtime access.

## Deviations from Plan

- The browser test exposed a pre-existing malformed vector command in `fa_wand_magic_sparkles.icon`. The icon source was fixed in this plan because the new Ask FSB toolbar button made that asset paint for the first time in browser tests.

## Issues Encountered

- Initial targeted browser test crashed during paint with a vector icon command failure. Splitting the invalid `MOVE_TO` argument sequence into `MOVE_TO` plus `LINE_TO` fixed the generated icon and made the toolbar test pass.

## Verification

- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default chrome` - passed for Task 1.
- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default browser_tests` - passed after Task 2.
- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default chrome browser_tests` - passed, no work remaining.
- `./out/Default/browser_tests --gtest_filter='*PrometheusToolbarEntryPoint*'` - passed, 1/1 test.
- `git -C .context/chromium/src diff --check` - passed.
- Acceptance marker scan confirmed `prometheus_side_panel_button_`, `prometheus_ask_fsb_button_`, `Toggle Prometheus side panel`, `Ask FSB`, and the wand icon path repair.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-04 can build on native Prometheus toolbar entry points and the compact layout reservation without introducing provider/runtime side effects.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
