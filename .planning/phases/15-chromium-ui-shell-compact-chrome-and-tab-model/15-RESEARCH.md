# Phase 15 Research - Chromium UI Shell, Compact Chrome, and Tab Model

**Researched:** 2026-07-07
**Status:** Complete

## Research Summary

Phase 15 should implement compact Prometheus chrome by adapting Chromium desktop
Views primitives rather than replacing the browser frame. The relevant ownership
boundaries are:

- `BrowserView` owns the desktop browser frame, top container, side panel,
  focus, accelerators, and widget lifecycle.
- `ToolbarView` owns navigation buttons, location bar, toolbar actions, tab
  search button accessors, and command updates.
- `HorizontalTabStripRegionView` and `TabStrip` own horizontal tab rendering.
- `TabStripModel`, `TabGroupModel`, `BrowserTabStripController`, and
  `browser_commands.cc` own tab actions and group state.
- `TabSearchBubbleHost` and `chrome://tab-search.top-chrome` already provide the
  top-chrome tab search surface.
- `SidePanelCoordinator` already owns side-panel visibility and content
  population.

The lowest-risk implementation is a staged Prometheus layer:

1. Add prefs/feature flags and tests for compact vs separate mode.
2. Add a compact layout path in Chromium Views that keeps the conventional path
   as fallback.
3. Add Prometheus toolbar entry points for side panel, Ask FSB, and tab search.
4. Add a stub tab-state provider for agent ownership/supervision/health badges.
5. Map Prometheus advanced-tab commands to Chromium-native tab commands.
6. Add visual/browser tests and export Phase 15 patches.

## Key Chromium Files

### Layout and top chrome

- `.context/chromium/src/chrome/browser/ui/views/frame/browser_view.h`
- `.context/chromium/src/chrome/browser/ui/views/frame/browser_view.cc`
- `.context/chromium/src/chrome/browser/ui/views/frame/browser_view_layout.*`
- `.context/chromium/src/chrome/browser/ui/views/frame/horizontal_tab_strip_region_view.*`
- `.context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.*`
- `.context/chromium/src/chrome/browser/ui/views/location_bar/location_bar_view.*`

### Tabs and tab commands

- `.context/chromium/src/chrome/browser/ui/tabs/tab_strip_model.h`
- `.context/chromium/src/chrome/browser/ui/tabs/tab_strip_model.cc`
- `.context/chromium/src/chrome/browser/ui/tabs/tab_group_model.h`
- `.context/chromium/src/chrome/browser/ui/views/tabs/browser_tab_strip_controller.*`
- `.context/chromium/src/chrome/browser/ui/browser_commands.cc`
- `.context/chromium/src/chrome/browser/ui/tabs/tab_menu_model.*`

### Tab search and side panel

- `.context/chromium/src/chrome/browser/ui/views/tab_search_bubble_host.*`
- `.context/chromium/src/chrome/browser/ui/webui/tab_search/`
- `.context/chromium/src/chrome/browser/ui/views/side_panel/side_panel_coordinator.*`
- `.context/chromium/src/chrome/browser/ui/views/side_panel/side_panel_toolbar_pinning_controller.*`

### Prometheus existing code from prior phases

- `.context/chromium/src/chrome/browser/prometheus/prometheus_action.*`
- `.context/chromium/src/chrome/browser/resources/prometheus/`
- `.context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.*`
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_view.*`
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.*`

## Implementation Approach

### Prefs and feature flags

Create a Prometheus-owned chrome mode preference with values:

- `separate` - conventional Chromium top chrome.
- `compact` - Prometheus compact mode.

The planner/executor may choose exact constants, but the user-facing labels are
`Separate` and `Compact`. Compact mode should be behind a feature flag or pref
default until browser tests prove it safe.

### Compact layout

Do not move all tab ownership into a new top bar. Instead, adapt Chromium's
existing top container:

- Keep `TabStrip` and `LocationBarView` as Chromium-owned controls.
- Add Prometheus compact sizing/layout logic that can make the active tab region
  act like the address/search field.
- Keep Search Tabs and side panel toggle outside tab overflow.
- Keep macOS traffic lights and titlebar drag regions native.

### Status affordances

Add a small Prometheus tab-state provider with safe defaults:

- owner: empty
- automation active: false
- supervision active: false
- tab health: ok

Phase 17 can replace the provider implementation with the real native agent
service. Phase 15 owns rendering stubs and tests, not real authorization.

### Advanced tab management

Prefer browser commands and `TabStripModel` over bespoke tab plumbing:

- Close/restore: existing Chromium tab close and restore commands.
- Duplicate: `DuplicateTab` / `DuplicateTabAt`.
- Detach/move: `MoveTabsToNewWindow`.
- Groups: `TabGroupModel`, `AddToNewGroup`, `ToggleGrouped`.
- Unload/suspend: Chromium discard/performance manager behavior where available.
- Reorder: `TabStripModel` move APIs and existing drag support.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking native window frame or traffic lights | Keep platform frame ownership in Chromium; avoid custom frame replacement. |
| Losing omnibox editing/focus behavior | Keep `LocationBarView` and Chromium command controller authoritative. |
| Compact tab overflow hides safety actions | Fixed placement rule: Search Tabs and side-panel toggle never hide behind tab overflow. |
| Stub agent labels look authoritative | Use safe defaults and test that no caller-provided label is trusted before Phase 17. |
| Copying Falkon/Qt tab code | Treat v1 code as behavior reference only; map to Chromium primitives. |
| Build time too high | Use targeted `autoninja` targets and browser test filters before full gate. |

## Validation Architecture

### Automated

- Unit/browser tests for pref registration, default mode, and compact/separate
  mode transitions.
- Views/browser tests for side panel toggle visibility, accessible name, and
  `SidePanelCoordinator` toggle behavior.
- Browser/UI tests for tab search reachability in compact mode.
- Unit tests for Prometheus tab-state safe defaults and badge model output.
- Browser tests for Prometheus command wrappers mapping to Chromium duplicate,
  detach, group, unload/discard, and close paths.
- Theme/color tests proving new controls consume `kColorPrometheus*` ids and
  repaint on dark/light changes.

### Manual / rendered

Capture rendered checks at 800px, 1280px, and 1728px+:

- no top-chrome overlap
- active address/search readable
- Search Tabs reachable
- side-panel toggle reachable
- focus rings visible
- long titles/URLs truncate cleanly
- dark/light switch repaints without layout jump

### Gate commands

- `.context/depot_tools/autoninja -C .context/chromium/src/out/Default chrome browser_tests prometheus_unittests`
- `.context/chromium/src/out/Default/prometheus_unittests`
- `.context/chromium/src/out/Default/browser_tests --gtest_filter='*Prometheus*Compact*:*Prometheus*Chrome*:*Prometheus*Tab*'`
- `bash .planning/chromium/check-chromium-env.sh`
- `bash .planning/chromium/check-falkon-gpl-guard.sh`
- `bash .planning/chromium/verify-artifact-isolation.sh`

## Research Complete

The planner should create staged plans with concrete Chromium file targets,
preserve separate layout throughout, and avoid custom frame replacement.
