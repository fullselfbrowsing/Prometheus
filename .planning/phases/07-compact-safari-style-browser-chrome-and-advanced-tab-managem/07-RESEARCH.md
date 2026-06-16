---
phase: 07
slug: compact-safari-style-browser-chrome-and-advanced-tab-managem
status: complete
created: 2026-06-16
---

# Phase 07 Research: Compact Browser Chrome and Advanced Tab Management

## Goal

Plan the compact Safari-style chrome and advanced tab-management work against the existing Falkon/Qt browser architecture without replacing core tab primitives.

## Existing Architecture

### Browser Chrome

- `falkon/src/lib/app/browserwindow.{h,cpp}` owns top-level window composition, startup focus, shortcuts, toolbar visibility, and accessors for `NavigationBar`, `TabWidget`, `LocationBar`, `TabModel`, and `TabMruModel`.
- `falkon/src/lib/navigation/navigationbar.{h,cpp}` builds the main toolbar row. It uses configurable widget IDs in `NavigationBar::loadSettings()` and `NavigationBar::reloadLayout()`, and it already hosts `m_window->tabWidget()->locationBars()` inside `m_navigationSplitter`.
- `falkon/src/lib/navigation/locationbar.{h,cpp}` owns address/search parsing, completion, site icon, privacy state, progress painting, and focus behavior. Compact mode should reuse this class rather than duplicating URL/search behavior in a new input.
- `falkon/src/lib/tabwidget/tabwidget.{h,cpp}` owns `TabBar`, location bar stack, add-tab buttons, closed-tab button, list-tabs button, and tab operations.
- `falkon/src/lib/tabwidget/tabbar.{h,cpp}` specializes `ComboTabBar`; it already loads settings from `Browser-Tabs-Settings`, handles width metrics, context menus, drag/drop, wheel behavior, and add-tab button movement.
- `falkon/src/lib/tabwidget/combotabbar.{h,cpp}` provides the low-level tab bar layout, overflow, pinned tab split, scrolling, elision, and tab size calculations.

### Tab Models and Management

- `falkon/src/lib/tabwidget/tabmodel.{h,cpp}` exposes tab roles for title, icon, pinned, restored, current, loading, audio, muted, and background activity. It also supports drag/drop tab moves and cross-window detach/insert.
- `falkon/src/lib/tabwidget/tabmrumodel.{h,cpp}` maintains most-recently-used ordering by moving the current tab to the top when `TabWidget::currentChanged` fires.
- `falkon/src/lib/tabwidget/tabcontextmenu.{h,cpp}` already wires reload, stop, duplicate, detach, load, unload, close, close-other, close-left/right, restore closed tab, pin, and mute actions. It also has confirmation helpers for multi-tab destructive actions.
- `falkon/src/lib/tools/closedtabsmanager.{h,cpp}` is the closed-tab persistence primitive behind restore/clear flows.
- `falkon/src/plugins/TabManager/` provides a useful reference for dense tab list UI, grouping by window/domain/host, filtering, drag/drop, and batch close/detach/unload.
- `falkon/src/plugins/VerticalTabs/` provides a useful reference for `QListView` + delegate tab rows, context menus, drag/drop, middle-click close, tooltips, and height calculations.

### Settings and Preferences

- Tab settings are persisted under `Browser-Tabs-Settings`.
- Existing tab preferences are loaded in `falkon/src/lib/preferences/preferences.cpp` around the tab settings block and saved in `Preferences::saveSettings()`.
- Existing tab preferences UI lives in `falkon/src/lib/preferences/preferences.ui` under the Tabs category and `tabsBehaviourPage`.
- Compact layout should add two persisted enum settings:
  - `tabLayout`: `Compact` or `Separate`; default `Separate` for compatibility.
  - `tabDisplay`: `TitleAndIcon` or `FaviconOnly`; default `TitleAndIcon`.
- Runtime setting changes should flow through `mApp->reloadSettings()` and existing `settingsReloaded` connections used by `TabWidget`, `TabBar`, `LocationBar`, and related surfaces.

### Agent and Supervision State

- `falkon/src/lib/agent/agentcommandrouter.{h,cpp}` owns the current in-memory tab ownership map (`m_tabOwners`) and supervision session map (`m_supervisionSessions`).
- `AgentCommandRouter::routeNewTab()` assigns ownership when an agent creates a tab.
- `AgentCommandRouter::enforceOwnership()` protects agent-owned target tabs.
- `AgentCommandRouter::showActionStatus()` currently exposes agent activity only through the status bar message.
- Phase 7 needs chrome-readable tab-state metadata. The lowest-risk path is to add query/read-only helpers on the agent runtime/router side, or a small shared tab-state provider, so `TabBar`/overview/search can render owner, active automation, supervision, and health without coupling paint code to JSON request handlers.

## Recommended Implementation Strategy

### Compact Chrome

Use existing widgets and layout primitives:

- Keep `LocationBar` as the editable active tab address/search control.
- In compact mode, hide or collapse the separate traditional tab row and host a compact tab strip/control cluster in the navigation row.
- Preserve separate mode by leaving current `NavigationBar` + `TabBar` behavior available and defaulted.
- Introduce explicit compact layout classes only where they reduce coupling, for example:
  - `CompactTabBar` or `CompactTabStrip` for toolbar-row tab rendering.
  - `TabOverviewDialog` or `TabOverviewPopup` for dense overview/search.
  - `TabGroupModel` only if group metadata cannot fit cleanly in `TabModel`.
- Avoid modifying `LocationBar::loadAction()` and completion logic unless required for focus/embedding behavior.

### Advanced Tab Management

Build new UI against `TabModel` and `TabMruModel` rather than direct tab list copies:

- Tab overview/search can use `QSortFilterProxyModel` over `TabModel`.
- Quick switch should use `TabMruModel`.
- Row actions should call existing `WebTab` and `TabWidget` operations, especially duplicate/detach/load/unload/close/restore.
- Drag reorder should reuse `TabModel::dropMimeData()` behavior where possible.
- Grouping can start with browser-native metadata stored in settings/session state and exposed through extra roles on `TabModel`.

### Visual Contract

The approved UI contract is `07-UI-SPEC.md`. The planner must preserve these hard values:

- Compact toolbar content height: 32px inside a 40px maximum row.
- Active compact address width: preferred 320px, minimum 180px, maximum 520px.
- Inactive tab width: preferred 144px, minimum 72px, maximum 176px.
- Pinned/favicon-only tabs: 32px.
- Search/overview rows: 32px.
- Accent `#ff6b35` is reserved for active focus, selected group marker, primary CTA, active automation, supervised state, and keyboard focus. It must not become general tab decoration.

## Risks and Pitfalls

- Duplicating `LocationBar` behavior would create inconsistent URL parsing, completion, and security icon behavior. Reuse the existing location bar stack.
- `ComboTabBar` has complex pinned/overflow/scroll behavior. Compact layout should not rewrite it wholesale without plan-level tests.
- Running multiple tab UI executors in parallel against `TabWidget`, `TabBar`, `ComboTabBar`, or `Preferences` would cause conflicts. Plans touching these files should be sequenced.
- Agent ownership currently lives in `AgentCommandRouter` internals. Rendering badges requires a stable read API, not ad-hoc access to private maps.
- Group metadata must survive tab moves, restore, duplicate, close/restore, and session save/restore. If session persistence is not in the first implementation slice, plans must explicitly document the limitation and avoid claiming full group persistence.
- Preferences `.ui` edits are XML-heavy and easy to break. Plans should include a generated build or `uic`/CMake verification where available.
- Visual verification may be limited in this workspace if Qt runtime dependencies are unavailable. Plans must include fallback compile/static verification plus manual visual checklist.

## Suggested Plan Decomposition

1. Settings and model foundations: persisted layout/display settings, tab group metadata roles, and agent/supervision read-only status hooks.
2. Compact chrome shell: navigation row integration, compact/separate switching, width constraints, focus routing, and favicon-only/title display.
3. Overview/search/quick-switch surfaces: dense native popover/dialog using `TabModel` and `TabMruModel`, including row actions.
4. Tab groups and advanced operations: group create/rename/collapse, drag/drop group movement, destructive confirmations, and close/restore behavior.
5. Verification and polish: keyboard shortcuts, tests, build, visual checklist, and documentation of any runtime/manual checks.

## Validation Architecture

### Build and Static Checks

- Run a CMake configure/build for the Falkon target if dependencies are present:
  - `cmake --build falkon/build --target Falkon`
  - If the target name differs, inspect `cmake --build falkon/build --target help`.
- At minimum, run `cmake --build falkon/build --target help` to verify the configured build tree is valid.
- Run `git diff --check` after generated UI and C++ edits.
- Use `rg` checks to verify new settings keys are loaded and saved:
  - `rg "tabLayout|tabDisplay|TitleAndIcon|FaviconOnly|Compact|Separate" falkon/src/lib`

### Unit/Integration Tests

- Extend existing tab tests where possible:
  - `falkon/autotests/tabmodeltest.cpp`
  - `falkon/autotests/locationbartest.cpp`
  - `falkon/autotests/webtabtest.cpp`
- Add model-level tests for new tab roles or group metadata if added to `TabModel`.
- Add non-visual tests for settings persistence if compact settings are implemented outside UI-only code.

### Manual Visual Checks

Verify these states on macOS or a Qt desktop runtime:

- Separate layout remains unchanged by default.
- Compact layout at 800px, 1280px, and 1728px+.
- Title-and-icon and favicon-only tab display without row-height changes.
- Active address/search focus from `Ctrl+L`, `Alt+D`, and File > Open Location.
- Overflow keeps Search Tabs reachable.
- Agent-owned, active automation, supervised, failed/stale, loading, audio, muted, pinned, restored/unloaded, private, and secure-origin states remain visually distinct.
- Tab overview/search empty, filtered, error/action-failed, and grouped states.

## Planner Constraints

- Every implementation plan must include a `<threat_model>` block because security enforcement is enabled.
- Every plan modifying UI must reference `07-UI-SPEC.md`.
- Every plan touching settings must include both load and save acceptance checks.
- Every plan touching tab actions must prove existing shortcuts and context-menu actions still route to existing `TabWidget` or `WebTab` operations.
- Plans should avoid parallel writes to the same chrome primitives; put conflicting files in later waves.

## RESEARCH COMPLETE
