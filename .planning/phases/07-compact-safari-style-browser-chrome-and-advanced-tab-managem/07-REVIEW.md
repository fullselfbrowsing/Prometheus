---
phase: 07-compact-safari-style-browser-chrome-and-advanced-tab-managem
reviewed: 2026-06-16T21:15:20Z
depth: standard
files_reviewed: 42
files_reviewed_list:
  - falkon/autotests/CMakeLists.txt
  - falkon/autotests/agentcommandroutertest.cpp
  - falkon/autotests/agentcommandroutertest.h
  - falkon/autotests/tabmodeltest.cpp
  - falkon/autotests/tabmodeltest.h
  - falkon/src/lib/CMakeLists.txt
  - falkon/src/lib/agent/agentcommandrouter.cpp
  - falkon/src/lib/agent/agentcommandrouter.h
  - falkon/src/lib/app/browserwindow.cpp
  - falkon/src/lib/app/browserwindow.h
  - falkon/src/lib/app/mainapplication.cpp
  - falkon/src/lib/app/mainapplication.h
  - falkon/src/lib/app/mainmenu.cpp
  - falkon/src/lib/app/mainmenu.h
  - falkon/src/lib/navigation/navigationbar.cpp
  - falkon/src/lib/navigation/navigationbar.h
  - falkon/src/lib/other/qzsettings.cpp
  - falkon/src/lib/other/qzsettings.h
  - falkon/src/lib/preferences/preferences.cpp
  - falkon/src/lib/preferences/preferences.ui
  - falkon/src/lib/tabwidget/compacttabdelegate.cpp
  - falkon/src/lib/tabwidget/compacttabdelegate.h
  - falkon/src/lib/tabwidget/compacttabfiltermodel.cpp
  - falkon/src/lib/tabwidget/compacttabfiltermodel.h
  - falkon/src/lib/tabwidget/compacttabstrip.cpp
  - falkon/src/lib/tabwidget/compacttabstrip.h
  - falkon/src/lib/tabwidget/tabcontextmenu.cpp
  - falkon/src/lib/tabwidget/tabcontextmenu.h
  - falkon/src/lib/tabwidget/tabgroupmodel.cpp
  - falkon/src/lib/tabwidget/tabgroupmodel.h
  - falkon/src/lib/tabwidget/tabmodel.cpp
  - falkon/src/lib/tabwidget/tabmodel.h
  - falkon/src/lib/tabwidget/tabsearchdelegate.cpp
  - falkon/src/lib/tabwidget/tabsearchdelegate.h
  - falkon/src/lib/tabwidget/tabsearchfiltermodel.cpp
  - falkon/src/lib/tabwidget/tabsearchfiltermodel.h
  - falkon/src/lib/tabwidget/tabsearchpopup.cpp
  - falkon/src/lib/tabwidget/tabsearchpopup.h
  - falkon/src/lib/tabwidget/tabwidget.cpp
  - falkon/src/lib/tabwidget/tabwidget.h
  - falkon/tools/fsb-baseline/release-validate.sh
  - falkon/tools/fsb-baseline/smoke-compact-tabs.sh
findings:
  critical: 3
  warning: 2
  info: 0
  total: 5
status: issues_found
---

# Phase 07: Code Review Report

**Reviewed:** 2026-06-16T21:15:20Z
**Depth:** standard
**Files Reviewed:** 42
**Status:** issues_found

## Summary

Reviewed Phase 07 compact chrome, tab group/search, native tab-state exposure, and validation scripts. The compact UI code is generally consistent with the phase contract, but the agent-facing tab state has security and correctness regressions: identities are spoofable, ownership/supervision is keyed to unstable tab indices, and the local agent endpoint lacks request authentication.

Non-mutating checks run: `git -C falkon diff --check` for reviewed paths, `bash -n falkon/tools/fsb-baseline/smoke-compact-tabs.sh`, and `bash -n falkon/tools/fsb-baseline/release-validate.sh` all passed. C++ build/tests were not rerun during this review.

## Critical Issues

### CR-01: Local Agent Endpoint Accepts Unauthenticated Commands

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentcommandrouter.cpp:259`
**Issue:** `POST /agent/command` routes any JSON body to `route()` with no token, pairing secret, origin validation, or connection identity check. `sendJson()` also emits `Access-Control-Allow-Origin: *` at line 294. A same-machine process, and a browser page that can guess the loopback port with a simple POST body, can issue tab/navigation/action commands without being a trusted MCP client.
**Fix:**
```cpp
// Require a browser-generated session token before dispatching commands.
if (!isAuthorizedAgentRequest(headers)) {
    sendJson(socket, QJsonObject{
        {QSL("ok"), false},
        {QSL("error"), QJsonObject{
            {QSL("code"), QSL("unauthorized")},
            {QSL("message"), QSL("Missing or invalid agent authorization.")}
        }}
    }, 401, QByteArrayLiteral("Unauthorized"));
    return;
}
sendJson(socket, route(document.object()));
```
Generate the token browser-side, bind it to a trusted client/session, remove wildcard CORS for command responses, and reject unauthenticated `OPTIONS`/simple POSTs.

### CR-02: Caller-Controlled Client Label Spoofs Agent Identity

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentcommandrouter.cpp:1405`
**Issue:** `agentIdForParams()` maps the request-supplied `client`/`clientLabel` string to the internal `agent-N` identity. `enforceOwnership()` then trusts only that `agentId` at lines 1437-1450. A second caller can send the same `client` label and receive the first agent's ID, bypassing tab ownership checks.
**Fix:** Treat `client` as display metadata only. Allocate identity from an authenticated connection/session controlled by the router, and bind ownership to that server-issued session key.
```cpp
const QString displayLabel = sanitizedDisplayLabel(params);
const QString sessionId = authenticatedSessionId(params);
const QString agentId = m_agentIds.value(sessionId);
```
Add a regression test where `client=A` owns a tab, a different authenticated session reuses `client=A`, and the second session still receives `TAB_OWNED_BY_OTHER_AGENT`.

### CR-03: Ownership and Supervision State Is Keyed to Unstable Tab Indices

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentcommandrouter.cpp:1290`
**Issue:** `targetKey()` uses `windowIndex:tabIndex`, and ownership/supervision/chrome state maps use that key. Phase 07 adds/reuses tab move, close, detach, group close, restore, and duplicate flows, but the router does not rekey or clear state on `TabWidget::tabMoved`/`tabRemoved`. After closing or moving a tab before an owned/supervised tab, state attaches to the wrong tab or disappears, allowing another agent to control a still-owned tab and causing compact chrome to show false owner/supervision badges.
**Fix:** Key router state by a stable tab identifier, preferably a UUID stored in `WebTab::sessionData()` or a `QPointer<WebTab>` plus cleanup on destruction. Store supervision targets by the same stable ID, and derive current window/tab indices only when producing `list_tabs`.
```cpp
QString AgentCommandRouter::targetKey(const Target &target) const
{
    return stableTabId(target.view ? target.view->webTab() : nullptr);
}
```
Add tests covering owned/supervised tab reorder, close-before-owned-tab, detach, restore, and group close.

## Warnings

### WR-01: Active Automation Badge Never Clears After Successful Actions

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentcommandrouter.cpp:1532`
**Issue:** `showActionStatus()` is called after commands complete and sets `activeAutomation=true`; the only paths that set it false are failure/close. Successful navigation, JS, manual actions, and supervision start leave the tab permanently marked as active automation, so compact chrome and destructive-action summaries keep reporting work that is no longer running.
**Fix:** Separate "last tool/reason" from active state. Set `activeAutomation=true` before long-running work, then set it false on success/failure/finalization or by a short one-shot timer after the status display expires.

### WR-02: Agent Read/Ownership Tests Assert Tokens Instead of Behavior

**File:** `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/autotests/agentcommandroutertest.cpp:46`
**Issue:** `listTabsContractIncludesGroupAndStateFields()` reads `agentcommandrouter.cpp` and checks whether strings exist. This passes if fields are dead code or stale, and it misses the index-key ownership break above. The smoke script similarly checks field presence/types but does not exercise reorder/close/detach/restore ownership behavior.
**Fix:** Replace the source-token test with behavioral QTest coverage that creates a window/tabs, assigns ownership and groups through router/UI paths, calls `list_tabs`, then moves/closes/restores/detaches tabs and asserts ownership, supervision, and group metadata stay attached to the same tab identity.

---

_Reviewed: 2026-06-16T21:15:20Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
