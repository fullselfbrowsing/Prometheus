# Phase 15 Pattern Map - Chromium UI Shell, Compact Chrome, and Tab Model

**Mapped:** 2026-07-07
**Status:** Complete

## File Classification

| Planned File | Role | Data Flow | Closest Existing Analog | Match Quality |
|--------------|------|-----------|--------------------------|---------------|
| `chrome/browser/prometheus/prometheus_chrome_mode.{h,cc}` | utility/config | pref mapping | `chrome/browser/prometheus/prometheus_action.{h,cc}` | role-match |
| `chrome/browser/prometheus/prometheus_chrome_mode_unittest.cc` | test | transform | `prometheus_action_unittest.cc` | exact |
| `chrome/common/pref_names.h` | config modify | pref declaration | existing `kTabSearch*`, `kSidePanel*` prefs | exact |
| `chrome/browser/prefs/browser_prefs.cc` | config modify | pref registration | existing tab search/side panel pref registration | exact |
| `chrome/browser/ui/views/toolbar/prometheus_toolbar_button.{h,cc}` | view | command/event | Chromium toolbar button classes | role-match |
| `chrome/browser/ui/views/toolbar/toolbar_view.*` | view modify | UI composition | existing `tab_search_button_`, pinned toolbar actions | exact |
| `chrome/browser/ui/views/frame/prometheus_compact_chrome_layout.{h,cc}` | layout helper | layout transform | `BrowserViewLayout`, `HorizontalTabStripRegionView` | role-match |
| `chrome/browser/ui/views/frame/browser_view_layout.*` | layout modify | geometry | existing top container layout | exact |
| `chrome/browser/prometheus/prometheus_tab_state.{h,cc}` | model/service | state projection | Phase 7 tab state decisions; Chromium tab helper patterns | role-match |
| `chrome/browser/prometheus/prometheus_tab_state_unittest.cc` | test | transform | existing Prometheus unit test target | exact |
| `chrome/browser/ui/views/tabs/prometheus_tab_status_badge.{h,cc}` | view | model-to-paint | `TabGroupUnderline`, tab alert icon patterns | role-match |
| `chrome/browser/prometheus/prometheus_tab_commands.{h,cc}` | adapter | command dispatch | `browser_commands.cc`, `TabStripModel::ExecuteContextMenuCommand` | role-match |
| `chrome/browser/prometheus/prometheus_tab_commands_browsertest.cc` | browser test | behavior | `tab_strip_model_browsertest.cc`, `tab_menu_model_unittest.cc` | role-match |
| `chrome/browser/ui/views/prometheus/prometheus_compact_chrome_browsertest.cc` | browser test | UI behavior | `tab_search_bubble_host_browsertest.cc`, side panel browsertests | role-match |

## Established Patterns

### Prometheus C++ helpers

Phase 14 introduced `chrome/browser/prometheus/` as the Prometheus-owned helper
namespace/target. New non-UI state helpers should live there and be covered by
`prometheus_unittests`.

### Chromium pref registration

Desktop profile prefs are declared in `chrome/common/pref_names.h` and
registered in `chrome/browser/prefs/browser_prefs.cc`. Phase 15 should follow
existing `kTabSearch*` and `kSidePanel*` style: string constant in pref names,
registration in profile prefs, helper API in Prometheus code.

### Toolbar buttons

`ToolbarView` owns toolbar button creation and command updates. New Prometheus
buttons should be normal Views toolbar buttons with accessible names and
tooltips, using `ui::ImageModel::FromVectorIcon` plus Prometheus color ids.

### Side panel

`SidePanelCoordinator::From(browser_window_interface)` is the visibility owner.
Do not directly show/hide side-panel child views from Prometheus code.

### Tab actions

Use `chrome/browser/ui/browser_commands.cc` and `TabStripModel` APIs as the
source of truth for duplicate, close, move, group, and pin/mute actions. Do not
implement second-order tab lists that mutate WebContents directly.

### Tests

Use `prometheus_unittests` for pure helpers and `browser_tests` filters for
Views/browser integration. Logs should be written under
`.context/chromium/src/out/Default/` with explicit exit-code markers.

## Pattern Map Complete
