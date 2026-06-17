---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 09 Plan 01 complete — FA SVG subset + brand fonts vendored offline
last_updated: "2026-06-17T08:57:39.820Z"
last_activity: 2026-06-17 -- Phase 10 planning complete
progress:
  total_phases: 10
  completed_phases: 9
  total_plans: 51
  completed_plans: 47
  percent: 92
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-16)

**Core value:** Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.
**Current focus:** Phase 09 — Offline Font Awesome Free Icon System and Minimal Themes

## Current Position

Phase: 10
Plan: Not started
Status: Ready to execute
Last activity: 2026-06-17 -- Phase 10 planning complete

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 47
- Average duration: 7min
- Total execution time: 0.3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 07 | 10 | 87min | 9min |
| 08 | 5 | - | - |
| 09 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: 07-06 through 07-10 completed, including review fixes and visual approval
- Trend: Phase 07 completed after verification, code review, and UI audit gates

*Updated after each plan completion*

**Recent Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 07 P02 | 9min | 2 tasks | 10 files |
| Phase 07 P03 | 8min | 2 tasks | 7 files |
| Phase 07 P04 | 5 min | 2 tasks | 5 files |
| Phase 07 P05 | 8min | 2 tasks | 8 files |
| Phase 07 P06 | 7min | 2 tasks | 7 files |
| Phase 07 P07 | 14min | 2 tasks | 10 files |
| Phase 07 P08 | 12min | 2 tasks | 10 files |
| Phase 07 P09 | 9min | 2 tasks | 10 files |
| Phase 07 P10 | 6min | 3 tasks | 4 files |
| Phase 08 P02 | 5min | 2 tasks | 6 files |
| Phase 08 P03 | 3min | 2 tasks | 2 files |
| Phase 08 P04 | 8min | 2 tasks | 2 files |
| Phase 08 P05 | 12min | 1 tasks | 4 files |
| Phase 09 P01 | 3 | 2 tasks | 78 files |
| Phase 09 P02 | 2min | 1 tasks | 4 files |
| Phase 09 P03 | 8min | 1 tasks | 3 files |
| Phase 09 P04 | 5min | 2 tasks | 10 files |
| Phase 09 P05 | 4min | 2 tasks | 7 files |
| Phase 09 P06 | 5min | 3 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- User steer: Product name is Prometheus; affiliation/tagline is "Powered by FSB".
- Initialization: Start from local Falkon/QtWebEngine fork.
- Initialization: Rebrand product-visible identity while preserving required legal notices.
- Initialization: Prioritize native agent control and MCP compatibility before full FSB runtime parity.
- Phase 5: Use a native Prometheus sidebar and `AgentRuntime` for task, provider, log, memory/site-guide, and vault surfaces.
- Phase 6: Use session-stamped DOM-native supervision tools and a local macOS validation package with legal/source bundle.
- Milestone extension: Use Safari compact mode as a reference for space-saving chrome, not as a visual clone.
- Milestone extension: Require an explicit FSB feature parity matrix before claiming "FSB but better".
- Milestone extension: Use a curated offline Font Awesome Free icon subset with attribution preserved and no network dependency.
- [Phase 07]: Use enum-backed QzSettings helpers as the canonical mapping between stored strings and runtime tab chrome settings.
- [Phase 07]: Keep Separate and TitleAndIcon as compatible defaults while presenting native Preferences labels exactly as specified.
- [Phase 07]: Expose tab chrome state as a router-owned whitelist instead of exposing request params or router internals.
- [Phase 07]: Use MainApplication::agentCommandRouter() as the native UI access path so TabModel does not own agent state.
- [Phase 07]: Return safe model defaults when the router is unavailable: empty owner, false automation/supervision, and health ok.
- [Phase 07]: Use a proxy/delegate/list-view primitive instead of moving the existing ComboTabBar into the navigation row.
- [Phase 07]: Route compact tab switching, close requests, context menus, and drag/drop through existing WebTab, TabWidget, TabContextMenu, and TabModel behavior.
- [Phase 07]: Partially stage CMake registration hunks for the Task 2 commit so unrelated pre-existing CMake changes remain uncommitted.
- [Phase 07]: Use a fixed compact NavigationBar row from qzSettings->tabLayout while preserving saved NavigationBar/Layout and ShowSearchBar behavior for Separate.
- [Phase 07]: Hide the conventional tab row with TabBar::setForceHidden() instead of moving tab ownership or LocationBar synchronization out of TabWidget.
- [Phase 07]: Use a QSortFilterProxyModel over either BrowserWindow::tabModel() or BrowserWindow::tabMruModel() so overview/search and quick switch share rendering without changing source order.
- [Phase 07]: Render only existing title, favicon, URL/domain, and sanitized TabModel state roles in the privileged popup.
- [Phase 07]: Keep the group filter as a hidden populated control slot until Plan 07-07 adds real group roles.
- [Phase 07]: Use BrowserWindow-owned one-shot TabSearchPopup instances with delete-on-close instead of long-lived shared popup state.
- [Phase 07]: Expose quick switch through a native File menu action with unused Ctrl+Shift+A metadata while preserving existing tab and location shortcuts.
- [Phase 07]: Place Tab Overview and Search Tabs after the active address/search field so compact tab overflow cannot hide Search Tabs.
- [Phase 07]: Expose group state through TabModel roles backed by TabGroupModel instead of extension pseudo-tabs.
- [Phase 07]: Store group membership on each WebTab through prometheusTabGroupId sessionData and keep group labels/colors/collapsed state in BrowserWindow TabGroups UI state.
- [Phase 07]: Normalize restored group IDs, labels, and colors before applying persisted session data.
- [Phase 07]: Keep group mutation MCP/native tool names as typed compatibility errors while exposing group state through list_tabs.
- [Phase 07]: Use disabled state rows and confirmation-body summaries to show owner/supervision state before destructive or group-moving UI actions.
- [Phase 07]: Leave group registry metadata intact when closing a group so Recently Closed Tabs can restore group membership.
- [Phase 07]: Use active tab, then TabMruModel, then source order as the representative precedence for collapsed groups.
- [Phase 07]: Use an internal ungrouped filter sentinel while keeping user-facing copy as Ungrouped.
- [Phase 07]: Group only Tab Overview into section order; Search Tabs and quick switch preserve source/MRU ordering semantics.
- [Phase 07]: Require health-issued bearer authorization for native agent commands and bind tab ownership to authenticated sessions, not caller-controlled client labels.
- [Phase 07]: Key agent tab ownership, supervision, and chrome state by stable tab IDs instead of mutable tab indices.
- [Phase ?]: FsbControlPanelPage uses QWidget with floating Window flags; routeForSession(request, control_panel) is the internal surface session key for native policy calls
- [Phase ?]: [09-01] arrow-down-to-line substituted with arrow-down: FA Free 6.x solid missing this glyph
- [Phase ?]: [09-01] sidebar-flip placeholder SVG created: Pro-only icon not in FA Free 6.x; minimal valid SVG with two-panel geometry and CC BY 4.0 attribution
- [Phase ?]: [09-01] 69 glyphs vendored offline (plan prose said 70 but enumerated list has 69 unique names)
- [Phase ?]: PrometheusMarkWidget: use qzcommon.h not falkon_defs.h for FALKON_EXPORT

### Roadmap Evolution

- Phase 7 added: Compact Safari-style browser chrome and advanced tab management.
- Phase 8 added: Native FSB-plus settings side panel and feature parity matrix.
- Phase 9 added: Offline Font Awesome Free icon system and minimal themes.
- Phase 8 edited: revised to side-panel four modes + FSB Control Panel page split per canonical design
- Phase 9 edited: added Poppins/Space Mono fonts, logo pass, warm two-theme tokens
- Phase 10 added: New Tab Start Page (design-driven new scope)

### Pending Todos

None yet.

### Blockers/Concerns

- Full internal namespace/class/library rename from Falkon to Prometheus is deferred; Phase 2 rebranded primary product-visible surfaces and preserved legal attribution.
- Phase 4 added a local stdio MCP bridge over the native JSON spine plus manual tools, ownership, diagnostics, and visual-session field handling.
- Phase 5 added local runtime surfaces and native-only secure secret storage. Provider-backed hosted model execution is still deferred.
- Phase 6 added PhantomStream-style supervision primitives, safe pairing, packaging, legal bundle validation, and full release validation.
- The generated artifact is a local validation package, not a notarized public macOS release.
- The first six phases include a basic native Prometheus side panel, but Phase 8 must turn it into a comprehensive control center and verify FSB-plus parity.
- Primary UI still uses many platform theme icons and inherited theme assets; Phase 9 must make primary icons deterministic, offline, and legally attributed.
- Phase 7 completed compact minimal chrome and advanced tab management. Phase 8 must upgrade the side panel/settings surface into a comprehensive FSB-plus control center with a verified parity matrix.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-06-17T08:08:26.526Z
Stopped at: Phase 09 Plan 01 complete — FA SVG subset + brand fonts vendored offline
Resume file: None
