---
phase: 08
plan: 05
subsystem: fsb-control-panel
tags: [control-panel, nine-sections, operator-ui, qt-widgets, vault, supervision, parity-matrix]
dependency_graph:
  requires: [08-01, 08-02, 08-03, 08-04]
  provides: [fsb-control-panel-page, control-panel-router-surface]
  affects: []
tech_stack:
  added: [QHeaderView, QProcess, QDesktopServices]
  patterns: [native-only-secret-save, routeForSession-internal-surface, parity-file-parse, QProcess-fixed-path]
key_files:
  created:
    - falkon/src/lib/agent/fsbcontrolpanel.h
    - falkon/src/lib/agent/fsbcontrolpanel.cpp
  modified:
    - falkon/src/lib/agent/agentcommandrouter.cpp
    - falkon/src/lib/CMakeLists.txt
decisions:
  - "FsbControlPanelPage inherits QWidget (not QDialog); router creates it as a floating Window with WA_DeleteOnClose"
  - "QListWidgetItem has no setMinimumHeight; use setSizeHint(QSize(w, 32)) as the 32px row height mechanism (same fix as Plan 08-04)"
  - "tabbedwebview.h included directly to resolve TabbedWebView incomplete type for weView()->url() in saveMemory"
  - "Section rail uses QListWidget at 130px fixed width; always visible (responsive QComboBox fallback is a Phase 9 polish item)"
  - "Parity Matrix parses FSB-PARITY.md columns 1/4/5/6 (Category/Status/Native Improvement/Validation) for condensed four-column view"
  - "savePermissions uses routeForSession(request, control_panel) for set_agent_policy; no direct m_agentCap mutation"
  - "QProcess for parity check smoke script uses QStringList args not a shell command string (T-08-05d)"
metrics:
  duration: 12min
  completed: "2026-06-17"
  tasks: 1
  files: 4
---

# Phase 08 Plan 05: FSB Control Panel Page Summary

Native FsbControlPanelPage QWidget class with all nine required operator sections (Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix) wired into the router via open_internal_surface surface=control_panel and registered in CMakeLists.txt.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create FsbControlPanelPage with all nine sections and wire into router | add182545 | fsbcontrolpanel.h, fsbcontrolpanel.cpp, agentcommandrouter.cpp, CMakeLists.txt |

## What Was Built

### fsbcontrolpanel.h

- `FALKON_EXPORT class FsbControlPanelPage : public QWidget` with `Q_OBJECT`
- Constructor: `explicit FsbControlPanelPage(BrowserWindow* window, QWidget* parent = nullptr)`
- Nine private build methods: `buildTasksSection`, `buildProvidersSection`, `buildMcpStatusSection`, `buildPermissionsSection`, `buildVaultSection`, `buildMemorySiteGuidesSection`, `buildLogsDiagnosticsSection`, `buildSupervisionSection`, `buildParityMatrixSection`
- All required private slot declarations and per-section member widget pointers

### fsbcontrolpanel.cpp

**Constructor:**
- `setObjectName("FsbControlPanelPage"); setMinimumSize(320, 400)`
- 48px header band: Display QLabel("Prometheus"), Label QLabel("Powered by FSB"), four compact status chips (MCP, Agents, Vault, Supervision) refreshed by `refreshAll()`
- 130px fixed-width `QListWidget` section rail + `QStackedWidget` with nine pages
- Connected `runtimeChanged` to `refreshAll()`; single-shot timer for initial population

**All nine section implementations:**

1. **Tasks** — 96px QPlainTextEdit prompt, Run Task (accent) + Cancel Task (destructive) buttons, QListWidget task rows showing status/prompt/execution-mode chip from `listTasks(20)`
2. **Providers & Models** — QListWidget provider rows (Key saved/No key saved, never raw key), QFormLayout detail with password-echo Key field, Save Provider + Discover Models (accent), fallback order list; `saveProvider()` calls `saveProviderConfig(id, config, allowSecretPayload=true)` then clears secret field
3. **MCP Status** — two-column QTableWidget populated from `diagnostics()` mcp/agents subtree; empty-state label; Refresh Diagnostics button
4. **Permissions & Agents** — eight-row QTableWidget (Preferences, Prometheus control center, Downloads, History, Vault, Provider settings, Supervision, Page JavaScript) with QComboBox Mode per row; QSpinBox agent cap (1–16) pre-populated from persisted setting; `savePermissions()` calls `routeForSession({"tool":"set_agent_policy","params":{"agentCap":N}}, "control_panel")`
5. **Vault** — QListWidget metadata rows (origin/label/secret-state chip/autofill; no raw secrets); Save Vault Entry form with password-echo secret field cleared after save; `saveVaultEntry()` calls `saveVaultSecret(origin, label, secret, autofill)`
6. **Memory & Site Guides** — two stacked QGroupBox sections; Memory list + 88px QPlainTextEdit editor; Site Guides list + 112px QPlainTextEdit editor; both backed by `listMemory()` / `listSiteGuides()`
7. **Logs & Diagnostics** — QComboBox filter (All/Task/Provider/Memory/Vault/Supervision/Error), QPlainTextEdit log view (Space Mono 9pt, read-only/selectable) from `listRuntimeLogs(100)`; diagnostic group QListWidget with nine groups; Export Diagnostics (JSON to temp file via QDesktopServices)
8. **Supervision & Pairing** — 48px summary row with pairing code (Space Mono 13pt bold), session ID, target, expiry labels from `diagnostics()` supervision block; Pair Dashboard (accent) / End Pairing / Unpair Dashboard (destructive) with confirmation dialogs
9. **Parity Matrix** — Open Parity Matrix button (opens FSB-PARITY.md via QDesktopServices::openUrl); QTableWidget parsing FSB-PARITY.md at display time (Category/Status/Improvement/Evidence columns); Run Parity Check button runs smoke script via QProcess with fixed QStringList args

### agentcommandrouter.cpp

- Added `#include "fsbcontrolpanel.h"`
- Added `wantsControlPanel = surface == "control_panel"` check
- Added `control_panel` branch in if-chain: creates `FsbControlPanelPage(windows.at(windowIndex))`, sets `Qt::Window` flags, `WA_DeleteOnClose`, window title, shows/raises/activates
- Updated unsupported-surface error message to list `control_panel` as a supported surface

### CMakeLists.txt

- Added `agent/fsbcontrolpanel.cpp` to the SRCS block alongside `agentruntimesidebar.cpp`
- Added `agent/fsbcontrolpanel.h` to the HDRS block alongside `agentruntimesidebar.h`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] QListWidgetItem has no setMinimumHeight method**

- Found during: Task 1 compilation
- Issue: Plan specified 32px row heights via `item->setMinimumHeight(32)` on QListWidgetItem instances, but QListWidgetItem does not have this method (same issue documented in Plan 08-04)
- Fix: Replaced with `item->setSizeHint(QSize(item->sizeHint().width(), 32))`; applied to all QListWidgetItem constructions in fsbcontrolpanel.cpp
- Files modified: fsbcontrolpanel.cpp
- Commit: add182545

**2. [Rule 3 - Blocking] QHeaderView incomplete type for setStretchLastSection**

- Found during: Task 1 compilation
- Issue: `m_permissionsTable->horizontalHeader()->setStretchLastSection(true)` required full QHeaderView definition; Qt's `qtableview.h` only forward-declares it
- Fix: Added `#include <QHeaderView>` to fsbcontrolpanel.cpp
- Files modified: fsbcontrolpanel.cpp
- Commit: add182545

**3. [Rule 3 - Blocking] TabbedWebView incomplete type in saveMemory**

- Found during: Task 1 compilation
- Issue: `m_window->weView()->url()` in `saveMemory()` requires full TabbedWebView definition; fsbcontrolpanel.cpp only had the mainapplication.h include chain
- Fix: Added `#include "tabbedwebview.h"` to fsbcontrolpanel.cpp
- Files modified: fsbcontrolpanel.cpp
- Commit: add182545

## Human Visual Verification

The following items require human visual confirmation and cannot be verified programmatically:

1. **Control panel window opens** — Run from a Prometheus build: POST `open_internal_surface` with `surface=control_panel` to the native agent port. The control panel window must open as a floating dialog with title "Prometheus Control Panel".

2. **All nine section names visible in section rail** — The left-side QListWidget must show exactly: Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, Parity Matrix.

3. **Sections are navigable** — Clicking each section name in the rail must switch the right-side QStackedWidget to the corresponding content page with no overlap or blank page.

4. **48px header band** — "Prometheus" in Display size + "Powered by FSB" tagline + four status chips (MCP, Agents, Vault, Supervision) must all be visible in a single 48px row at default window width.

5. **Secret fields use password echo** — Key fields in Providers and Vault sections must show dots/bullets rather than plain text when typing.

6. **Provider list shows Key saved / No key saved** — Provider QListWidget rows must not show actual API key values.

7. **Vault list shows metadata only** — Vault QListWidget rows must show origin, label, and secret-state chip; no raw secret values.

8. **Parity Matrix section** — "Open Parity Matrix" button must be present; QTableWidget below must show parity rows parsed from FSB-PARITY.md.

9. **No layout overlap at 320px** — At minimum width no text or button may overlap an adjacent element.

10. **Side panel four modes** — Ctrl+Shift+P still opens the four-mode side panel (FSB Agent, Explorer, Tabs, Tools) unchanged from Plan 08-04.

## Known Stubs

| Stub | File | Notes |
|------|------|-------|
| Section rail always visible | fsbcontrolpanel.cpp | Responsive QComboBox fallback at <420px not implemented; rail is always 130px. Phase 9 polish item. |
| Model discovery — no live API | fsbcontrolpanel.cpp (discoverModels) | Discover Models reads cached `models` array from providerConfig(); real per-provider live enumeration is deferred per parity matrix row |
| Diagnostics group detail pane | fsbcontrolpanel.cpp (buildLogsDiagnosticsSection) | Clicking a diagnostic group shows no detail pane; pane would require a second QStackedWidget or QTextBrowser; placeholder only |
| Fallback order drag/drop | fsbcontrolpanel.cpp (buildProvidersSection) | Fallback order QListWidget has no drag/drop or up/down buttons; Save Fallbacks button is present but not connected |

## Threat Flags

No new trust boundaries introduced beyond those documented in the plan threat model. All vault/provider secret flows use native-only paths. No raw secret values appear in any list row, log, or parity file.

## Self-Check: PASSED

- [x] falkon/src/lib/agent/fsbcontrolpanel.h exists with FsbControlPanelPage and nine build method declarations
- [x] falkon/src/lib/agent/fsbcontrolpanel.cpp exists with all nine section implementations
- [x] `rg buildTasksSection falkon/src/lib/agent/fsbcontrolpanel.cpp` — matches (18 occurrences across header and 9 builders)
- [x] `rg control_panel falkon/src/lib/agent/agentcommandrouter.cpp` — matches (wantsControlPanel check, if-branch, error message)
- [x] `rg fsbcontrolpanel falkon/src/lib/CMakeLists.txt` — matches (.cpp and .h registered)
- [x] `rg 'agentRuntime()->listTasks|listVaultEntries|diagnostics' falkon/src/lib/agent/fsbcontrolpanel.cpp` — matches 5 lines
- [x] `rg 'echoMode|Password' falkon/src/lib/agent/fsbcontrolpanel.cpp` — matches (providerSecret and vaultSecret)
- [x] `rg 'clear()' falkon/src/lib/agent/fsbcontrolpanel.cpp` — matches m_providerSecret->clear() and m_vaultSecret->clear()
- [x] `rg 'routeForSession.*control_panel' falkon/src/lib/agent/fsbcontrolpanel.cpp` — matches savePermissions, pairDashboard, endPairing
- [x] Commit add182545 exists in falkon sub-repo
- [x] `cmake --build ... --target FalkonPrivate -j2` exits 0 with no new errors (only pre-existing deprecation warnings)
- [x] `ctest -R agentcommandroutertest --output-on-failure` exits 0 (1/1 test passed)
- [x] No raw secret values in fsbcontrolpanel.cpp or fsbcontrolpanel.h
