---
phase: 08-native-fsb-plus-settings-side-panel-and-feature-parity-matrix
reviewed: 2026-06-16T00:00:00Z
depth: deep
files_reviewed: 16
files_reviewed_list:
  - src/lib/agent/agentcommandrouter.cpp
  - src/lib/agent/agentcommandrouter.h
  - src/lib/agent/agentruntime.cpp
  - src/lib/agent/agentruntime.h
  - src/lib/agent/fsbcontrolpanel.cpp
  - src/lib/agent/fsbcontrolpanel.h
  - src/lib/agent/agentruntimesidebar.cpp
  - src/lib/agent/agentruntimesidebar.h
  - src/lib/preferences/preferences.cpp
  - src/lib/preferences/preferences.ui
  - autotests/agentcommandroutertest.cpp
  - autotests/agentcommandroutertest.h
  - src/lib/CMakeLists.txt
  - tools/fsb-baseline/FSB-PARITY.md
  - tools/fsb-baseline/smoke-fsb-plus-parity.sh
  - tools/fsb-baseline/release-validate.sh
findings:
  critical: 4
  warning: 5
  info: 3
  total: 12
status: resolved
resolved_at: 2026-06-16T00:00:00Z
fixed:
  - CR-01
  - CR-02
  - CR-03
  - CR-04
  - WR-01
  - WR-02
  - WR-03
  - WR-04
  - WR-05
deferred:
  - IN-01
  - IN-02
  - IN-03
---

# Phase 08: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** deep
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 8 adds the FSB-Plus Settings side panel (`FsbControlPanelPage`), the four-mode sidebar restructure (`AgentRuntimeSidebarWidget`), the `PrometheusRuntime/Policy` group wiring through both Preferences and the router, and the `get_agent_policy`/`set_agent_policy` MCP routes. The security boundary architecture (vault native-only, secret transport blocking, `PERMISSION_BLOCKED` and `PROVIDER_NOT_CONFIGURED` error codes) is fundamentally sound. However, four bugs make phase-8 functionality ship broken or insecure.

---

## Structural Findings (fallow)

No structural pre-pass was provided for this phase.

---

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Provider secret never stored from native UI (apiKey vs secret key mismatch)

**File:** `src/lib/agent/fsbcontrolpanel.cpp:1146` and `src/lib/agent/agentruntime.cpp:339`

**Issue:** `FsbControlPanelPage::saveProvider()` writes the user-entered API key into `config["apiKey"]` before calling `saveProviderConfig(providerId, config, /*allowSecretPayload=*/true)`. However `AgentRuntime::saveProviderConfig` reads the secret from `config.value(QSL("secret"))` (line 339), not from `"apiKey"`. The field names do not match, so `secret` is always empty and `storeSecret()` is never called. Every "Save Provider" click silently succeeds (returns `ok:true`, label says "Key saved") but the keychain/fallback file is never written. Operators have no indication the key was discarded. This makes every provider non-functional from the native control panel.

**Fix:** In `fsbcontrolpanel.cpp` line 1146, change the config key to match the field name that `saveProviderConfig` reads:
```cpp
// was: config[QSL("apiKey")] = secret;
config[QSL("secret")] = secret;
```

---

### CR-02: `FsbControlPanelPage::runTask` stores empty `m_currentTaskId` (wrong JSON path)

**File:** `src/lib/agent/fsbcontrolpanel.cpp:1089`

**Issue:** `AgentRuntime::submitTask` returns `{ok:true, task:{id:"task-...", ...}}`. `runTask()` extracts the task ID with `result.value(QSL("taskId")).toString()`, which looks for a top-level `"taskId"` key that does not exist. The correct path is `result["task"]["id"]`. As a result `m_currentTaskId` is always empty string after every submission. Clicking "Cancel Task" then falls into the `m_currentTaskId.isEmpty()` branch and either cancels a list-selected task (unrelated one) or does nothing. There is no way to cancel the just-submitted task from the control panel's own tracking.

**Fix:**
```cpp
// was: m_currentTaskId = result.value(QSL("taskId")).toString();
m_currentTaskId = result.value(QSL("task")).toObject().value(QSL("id")).toString();
```

---

### CR-03: `internalSurfaceControl` default mismatch — feature disabled by default in Preferences, enabled by default in router

**File:** `src/lib/preferences/preferences.cpp:594` vs `src/lib/agent/agentcommandrouter.cpp:915`

**Issue:** The policy key `internalSurfaceControl` controls whether agents can call `open_internal_surface`. The router reads the setting with default `true` (line 915); Preferences loads it with default `false` (line 594). On a fresh profile with no stored setting, the router will allow `open_internal_surface` while the Preferences dialog shows the checkbox unchecked (feature appears off to the operator). If the operator opens Preferences and saves without touching that checkbox, it writes `false` to Settings, and from that point forward the router will deny `open_internal_surface`. This is a silent security-policy reversal that depends on whether the operator has ever opened Preferences.

The same default mismatch exists for `supervisionPairing`: router default is `true` (line 1258), Preferences default is `false` (line 599).

**Fix:** Align defaults. The secure posture should be the out-of-box default. If `internalSurfaceControl` should be off by default, change the router:
```cpp
// agentcommandrouter.cpp line 915 and line 1250
const bool internalSurfaceEnabled = policySettings.value(
    QSL("PrometheusRuntime/Policy/internalSurfaceControl"), false).toBool();
```
And in `routeGetAgentPolicy` line 1250:
```cpp
const bool internalSurfaceControl = settings.value(QSL("internalSurfaceControl"), false).toBool();
```
Apply the same correction for `supervisionPairing` (router line 1258 -> default `false`).

---

### CR-04: `executionChip` never shown in sidebar — status `"complete"` vs `"completed"` mismatch

**File:** `src/lib/agent/agentruntimesidebar.cpp:406`

**Issue:** `AgentRuntime::finishTask` stores `task["status"] = "complete"` (line 184 of agentruntime.cpp). The sidebar's `refreshFsbAgent()` displays the execution mode chip only when `status == "completed"` (line 406 of agentruntimesidebar.cpp). The strings never match, so the execution mode chip (`[Execution: Local/offline]`, `[Execution: Provider]`, etc.) is never displayed for any completed task. This is the primary Phase 8 UX deliverable for completed tasks in the sidebar and it is permanently dead code.

**Fix:**
```cpp
// agentruntimesidebar.cpp line 406
if (!executionChip.isEmpty() && (status == QSL("complete") || status == QSL("cancelled") || status == QSL("failed"))) {
```

---

## Warnings

### WR-01: `routeSetAgentPolicy` writes two audit records per call

**File:** `src/lib/agent/agentcommandrouter.cpp:1329-1331`

**Issue:** `routeSetAgentPolicy` calls `writeAudit(...)` explicitly at line 1329, then immediately returns `success(...)` at line 1331. `success()` calls `writeAudit` again internally (line 453). Each `set_agent_policy` call therefore writes two audit log entries with different sequence numbers: one with `details={policyUpdated:true}` and a second with `details=<full result object>`. The audit trail is doubled and the sequence numbers diverge from the true request count.

**Fix:** Remove the explicit `writeAudit` call at line 1329 and rely solely on the one emitted by `success()`:
```cpp
// Remove this line:
// writeAudit(id, tool, true, QString(), QJsonObject{{QSL("policyUpdated"), true}, {QSL("agentCap"), m_agentCap}});
return success(id, tool, QJsonObject{{QSL("applied"), true}, {QSL("agentCap"), m_agentCap}}, auditSequence);
```

---

### WR-02: `pairDashboard` and `endPairing` send empty params — supervision always fails from control panel

**File:** `src/lib/agent/fsbcontrolpanel.cpp:1283-1308`

**Issue:** `pairDashboard()` sends `start_supervision_session` with empty params `{}`. `routeSupervision` then calls `resolveTarget(params, ...)`, which falls back to `windowIndex=0` and `tabIndex=currentIndex()`. This is fragile but may work. However `endPairing()` sends `end_supervision_session` with empty params `{}`, so `sessionId` will be an empty string. `routeSupervision` line 1391 checks `sessionId.isEmpty()` first and returns `STALE_SUPERVISION_SESSION` immediately. There is no way to end an active supervision session from the control panel; the "End Pairing" and "Unpair Dashboard" buttons always silently fail (the `routeForSession` return value is discarded).

**Fix:** The control panel needs to track the active session ID. Store the `sessionId` from the `create_supervision_pairing` response and pass it in `end_supervision_session`:
```cpp
// In pairDashboard():
const QJsonObject response = mApp->agentCommandRouter()->routeForSession(request, QSL("control_panel"));
if (response.value(QSL("ok")).toBool()) {
    m_activeSupervisionSessionId = response.value(QSL("result")).toObject()
        .value(QSL("session")).toObject().value(QSL("sessionId")).toString();
}

// In endPairing():
const QJsonObject request = QJsonObject{
    {QSL("tool"), QSL("end_supervision_session")},
    {QSL("params"), QJsonObject{{QSL("sessionId"), m_activeSupervisionSessionId}}}
};
```
Add `QString m_activeSupervisionSessionId` to the header.

---

### WR-03: Smoke script checks `dom_snapshot`/`page_snapshot` but health array exports `get_dom_snapshot`/`get_page_snapshot`

**File:** `tools/fsb-baseline/smoke-fsb-plus-parity.sh:236`

**Issue:** The live parity smoke checks the `/health` tools array for `dom_snapshot` and `page_snapshot`. The actual tool names exported by the router are `get_dom_snapshot` and `get_page_snapshot` (agentcommandrouter.cpp lines 419-420). The smoke will always fail the live tool-presence check if a binary is available, printing false negative parity failures.

**Fix:**
```bash
# smoke-fsb-plus-parity.sh line 236
for required_tool in diagnostics list_tabs new_tab get_dom_snapshot get_page_snapshot; do
```

---

### WR-04: `vaultBoundary` read twice from QSettings in `routeGetAgentPolicy`

**File:** `src/lib/agent/agentcommandrouter.cpp:1255-1257`

**Issue:** The ternary that guards against an empty `vaultBoundary` calls `settings.value(QSL("vaultBoundary"), QSL("native_only"))` twice — once to check for empty and once to get the final value. Between an end-group call and a begin-group call, QSettings does not re-enter the group, but within the already-open group this is merely redundant work. The more important concern is readability: a reader must verify that both calls are identical, creating confusion about whether two different keys were intended.

**Fix:**
```cpp
// Replace lines 1255-1257 with:
const QString rawVaultBoundary = settings.value(QSL("vaultBoundary"), QSL("native_only")).toString().trimmed();
const QString vaultBoundary = rawVaultBoundary.isEmpty() ? QSL("native_only") : rawVaultBoundary;
```

---

### WR-05: `AgentRuntimeSidebarWidget` modeSwitcher creates four dummy `QWidget` tabs wasting layout space

**File:** `src/lib/agent/agentruntimesidebar.cpp` (constructor, `modeSwitcher->addTab` calls)

**Issue:** The sidebar uses a `QTabWidget` (`modeSwitcher`) only as a segmented-control switcher, with the actual content pages in a separate `QStackedWidget`. To do this, it inserts four empty `QWidget` instances as tab content via `modeSwitcher->addTab(new QWidget(modeSwitcher), ...)`. `QTabWidget` will allocate a content area for these dummy widgets, adding a non-zero vertical chrome region above `m_modeStack` even though the content area is empty. On a 320 px-wide sidebar this wastes approximately 20-30 px of height. The `setMaximumHeight(36)` call partially mitigates this but the dummy children still consume memory and participate in layout passes.

**Fix:** Use a `QTabBar` directly to avoid allocating content areas for the tabs, or set the tab content widget to `nullptr`:
```cpp
// Replace QTabWidget with QTabBar for the mode switcher
auto* modeSwitcher = new QTabBar(this);
modeSwitcher->addTab(tr("FSB Agent"));
modeSwitcher->addTab(tr("Explorer"));
modeSwitcher->addTab(tr("Tabs"));
modeSwitcher->addTab(tr("Tools"));
connect(modeSwitcher, &QTabBar::currentChanged, m_modeStack, &QStackedWidget::setCurrentIndex);
```

---

## Info

### IN-01: `settingsCap` read but immediately unused in `routeGetAgentPolicy`

**File:** `src/lib/agent/agentcommandrouter.cpp:1248-1249`

**Issue:** `routeGetAgentPolicy` reads `settingsCap` from QSettings then immediately suppresses the unused-variable warning with `Q_UNUSED(settingsCap)`. The response already returns `m_agentCap` (the live runtime cap). The settings read serves no purpose at this call site and adds noise to both the code and the QSettings I/O path.

**Fix:** Remove lines 1248-1249 entirely. The comment on line 1247 adequately explains why `m_agentCap` (not the settings value) is returned.

---

### IN-02: `routeSetProviderConfig` includes `"secret"` in the propagated key list

**File:** `src/lib/agent/agentcommandrouter.cpp:1227`

**Issue:** The key list `{enabled, displayName, model, endpoint, models, secret}` copies a `"secret"` field from MCP params into `config`, which is then blocked by `saveProviderConfig(..., false)` returning `SECRET_TRANSPORT_BLOCKED`. The block is correct, but the intent is obscure: the key is in the propagation list only to surface the blocking error. A reader must trace through `saveProviderConfig` to understand this is not a bypass. A comment would prevent future maintainers from either removing the key (losing the error path) or mistaking it for a permitted field.

**Fix:** Add a comment and consider explicitly rejecting `"secret"` before the loop, which also avoids the unnecessary insertion into `config`:
```cpp
// Explicitly block secret on the remote transport before building config.
if (params.contains(QSL("secret")) || params.contains(QSL("apiKey"))) {
    return failure(id, tool, QSL("SECRET_TRANSPORT_BLOCKED"),
                   QSL("Provider secrets can only be stored from the native Prometheus UI."),
                   auditSequence);
}
const QStringList keys{QSL("enabled"), QSL("displayName"), QSL("model"), QSL("endpoint"), QSL("models")};
```

---

### IN-03: Sidebar `refreshExplorer` adds "No reading list items" permanently to the list

**File:** `src/lib/agent/agentruntimesidebar.cpp` (`refreshExplorer`)

**Issue:** The Reading List section checks `if (m_readingList && m_readingList->count() == 0)` and adds a placeholder. But `refreshExplorer` is called from `refreshAll` which is connected to `AgentRuntime::runtimeChanged`. Each runtime-changed signal will re-enter `refreshExplorer`, and because `m_readingList->clear()` is not called at the top of the Reading List block (unlike Bookmarks and History), the `count() == 0` guard prevents re-adding. This is safe for the placeholder but means a future implementation that populates reading list items will silently fail to clear stale placeholder items between refreshes if the list transitions from non-empty back to empty.

**Fix:** Mirror the clear-then-populate pattern used for Bookmarks and History:
```cpp
if (m_readingList) {
    m_readingList->clear();
    // TODO: populate reading list items when API is available
    if (m_readingList->count() == 0) {
        m_readingList->addItem(tr("No reading list items"));
    }
}
```

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
