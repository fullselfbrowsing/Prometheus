---
phase: 08
plan: 04
subsystem: agent-sidebar
tags: [side-panel, four-mode, fsb-agent, explorer, tabs, tools, qt-widgets]
dependency_graph:
  requires: [08-02]
  provides: [four-mode-side-panel-shell]
  affects: [08-05]
tech_stack:
  added: [QStackedWidget, QCheckBox, QShortcut]
  patterns: [runtime-owns-state, agent-aware-tab-roles, segmented-mode-switcher]
key_files:
  created: []
  modified:
    - falkon/src/lib/agent/agentruntimesidebar.cpp
    - falkon/src/lib/agent/agentruntimesidebar.h
decisions:
  - "Four-mode switcher uses QTabWidget(document mode) for labels only; content lives in QStackedWidget m_modeStack below it — avoids QTabWidget managing page content and avoids double layout"
  - "Explorer reading list shows empty-state placeholder; no reading list API available in Phase 8 — Plan 08-05 may wire if runtime exposes one"
  - "Pinned tabs excluded from Open now list to avoid duplication; each tab shows in exactly one section"
  - "TabGroupModel::tabsInGroup used for group member counts; requires tabGroupModel() from BrowserWindow::tabWidget()"
metrics:
  duration: 8min
  completed: "2026-06-16"
  tasks: 2
  files: 2
---

# Phase 08 Plan 04: Four-Mode Side Panel Restructure Summary

Replaced the five dense-operator tabs (Task/Providers/Logs/Memory/Vault) with a four-mode segmented switcher (FSB Agent, Explorer, Tabs, Tools) backed by a QStackedWidget, set 320px minimum width, and implemented all four mode pages with runtime-backed content and agent-aware state.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Restructure side panel header, mode switcher, and shell | 11427c0c6 | agentruntimesidebar.h, agentruntimesidebar.cpp |
| 2 | Implement four mode page builders with runtime-backed content | 11427c0c6 | agentruntimesidebar.cpp |

## What Was Built

### agentruntimesidebar.h

- Replaced five old build method declarations (buildTaskPage, buildProviderPage, buildLogsPage, buildMemoryPage, buildVaultPage) with four new mode builders: `buildFsbAgentPage`, `buildExplorerPage`, `buildTabsPage`, `buildToolsPage`
- Added new slot declarations: `runTask()`, `cancelCurrentTask()`, `refreshFsbAgent()`, `refreshExplorer()`, `refreshTabsMode()`, `refreshAll()`
- Added `QStackedWidget* m_modeStack` plus four-mode member widgets
- Replaced dense per-tab members with clean four-mode member set
- Added forward declarations for `QCheckBox`, `QPushButton`, `QStackedWidget`, `QTabWidget`

### agentruntimesidebar.cpp (constructor)

- `setMinimumWidth(320)` per 08-UI-SPEC.md
- Root layout `setContentsMargins(8, 8, 8, 8)` and `spacing(8)`
- Header: Prometheus title (bold, larger font) + "Powered by FSB" tagline
- Mode switcher: `QTabWidget(documentMode, maxHeight 36)` with four tabs (FSB Agent, Explorer, Tabs, Tools) acting as switcher only
- `m_modeStack` QStackedWidget connected to switcher via `currentChanged -> setCurrentIndex`
- Four pages built and added to m_modeStack
- Single `runtimeChanged` connection to `refreshAll()`

### FSB Agent page (`buildFsbAgentPage`)

- Status pill QLabel("Ready") with objectName "agentStatusPill"
- Message stream QListWidget (non-editable); items show role prefix + text
- Completed task items show execution-mode chip: `[Execution: Provider]`, `[Execution: Local/offline]`, `[Execution: MCP]` read from `task.metrics.executionMode`
- 96px fixed-height QPlainTextEdit composer with "Ask Prometheus to work in this browser..." placeholder
- Run Task button (accent property) with Ctrl+Enter shortcut
- Cancel Task button (destructive property) hidden until active task is running

### Explorer page (`buildExplorerPage`)

- Nested QTabWidget (document mode) with three sub-tabs: Bookmarks, Reading List, History
- Bookmarks: walks BookmarkItem tree from `mApp->bookmarks()->rootItem()` showing title+URL; navigate on double-click
- Reading List: empty-state placeholder "No reading list items" (no reading list API in Phase 8)
- History: uses `mApp->history()->mostVisited(50)` showing title+URL; navigate on double-click

### Tabs page (`buildTabsPage`)

- Pinned section: filters `TabModel::PinnedRole == true` rows; shows title, icon, agent-aware badges (A=automation, S=supervision, [owner])
- Groups section: reads `TabGroupModel` via `m_window->tabWidget()->tabGroupModel()`; shows group name + member count from `tabsInGroup()`
- Open now section: all non-pinned tabs with current-tab marker (*), agent-aware badges reading Phase 7 roles (TabOwnerRole, ActiveAutomationRole, SupervisionRole)

### Tools page (`buildToolsPage`)

- Reader mode, Focus highlight, Force dark site as QCheckBox toggle rows (placeholder stubs — no backend API in Phase 8)
- Annotate chip row: QLabel placeholder
- FSB on this page button: switches m_modeStack to index 0 (FSB Agent mode)

## Methods Relocated for Plan 08-05

The following build methods and slots from the old sidebar have been **removed** from `agentruntimesidebar.cpp`. Plan 08-05 (`FsbControlPanelPage`) must re-implement them for the operator control panel page:

| Method | Old location | Plan 08-05 target |
|--------|-------------|-------------------|
| `buildTaskPage` | agentruntimesidebar.cpp | FsbControlPanelPage Tasks section |
| `buildProviderPage` | agentruntimesidebar.cpp | FsbControlPanelPage Providers & Models section |
| `buildLogsPage` | agentruntimesidebar.cpp | FsbControlPanelPage Logs & Diagnostics section |
| `buildMemoryPage` | agentruntimesidebar.cpp | FsbControlPanelPage Memory & Site Guides section |
| `buildVaultPage` | agentruntimesidebar.cpp | FsbControlPanelPage Vault section |
| `saveProvider()` | agentruntimesidebar.cpp | FsbControlPanelPage provider save |
| `saveMemory()` | agentruntimesidebar.cpp | FsbControlPanelPage memory save |
| `saveSiteGuide()` | agentruntimesidebar.cpp | FsbControlPanelPage site guide save |
| `saveVaultEntry()` | agentruntimesidebar.cpp | FsbControlPanelPage vault save |
| `refreshProvider()` | agentruntimesidebar.cpp | FsbControlPanelPage refresh |
| `refreshLogs()` | agentruntimesidebar.cpp | FsbControlPanelPage refresh |
| `refreshMemory()` | agentruntimesidebar.cpp | FsbControlPanelPage refresh |
| `refreshVault()` | agentruntimesidebar.cpp | FsbControlPanelPage refresh |

The implementation logic for all these methods is preserved in the git history at the commit immediately before 11427c0c6 (the prior Phase 5 sidebar). Plan 08-05 should read the old `agentruntimesidebar.cpp` via `git show` to adopt the existing provider/memory/vault/logs implementations rather than re-implementing from scratch.

Old member variables that should be re-declared in `FsbControlPanelPage`:
`m_promptEdit`, `m_taskList`, `m_taskStatus`, `m_providerCombo`, `m_providerModel`, `m_providerEndpoint`, `m_providerSecret`, `m_providerStatus`, `m_logView`, `m_memoryKey`, `m_memoryText`, `m_memoryList`, `m_siteOrigin`, `m_siteGuideText`, `m_siteGuideList`, `m_vaultOrigin`, `m_vaultLabel`, `m_vaultSecret`, `m_vaultList`, `m_vaultStatus`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] QListWidget has no setMinimumItemHeight method**

- Found during: Task 1/2 implementation
- Issue: Plan specified 32px minimum row height for QListWidget items using setMinimumItemHeight, which does not exist in Qt's QListWidget API
- Fix: Removed the calls; QListWidget item height is controlled via delegate or item size hints, not a single-call API. The 32px target from the spec remains achievable via stylesheets or a custom delegate which Phase 9 (icon system and themes) can add.
- Files modified: agentruntimesidebar.cpp
- Commit: 11427c0c6

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| Reading list: empty state | agentruntimesidebar.cpp | refreshExplorer() | No reading list data API available in Phase 8; will need wiring when API is added |
| Tools checkboxes: not connected | agentruntimesidebar.cpp | buildToolsPage() | No page-level reader/dark/focus APIs exposed yet; Phase 9/10 can connect |

## Threat Flags

No new trust boundaries introduced. All data flows through existing runtime APIs.

## Self-Check: PASSED

- [x] falkon/src/lib/agent/agentruntimesidebar.h exists and contains m_modeStack
- [x] falkon/src/lib/agent/agentruntimesidebar.cpp exists and contains buildFsbAgentPage implementation
- [x] Commit 11427c0c6 exists in falkon sub-repo (`git -C falkon log --oneline -1`)
- [x] Build exits 0 (FalkonPrivate target)
- [x] agentcommandroutertest passes (Plan 02 tests unaffected)
