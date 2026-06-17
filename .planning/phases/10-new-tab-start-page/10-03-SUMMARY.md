---
phase: 10
plan: 03
subsystem: start-page
tags: [start-page, qwebchannel, bridge, security, agent-sidebar]
dependency_graph:
  requires:
    - falkon:start HTML (10-02)
    - AgentRuntimeSidebarWidget (phase 08)
  provides:
    - PrometheusStartBridge (qz_prometheus_start) registered URL-guarded to falkon:start
    - seedPromptAndOpen public slot on AgentRuntimeSidebarWidget
    - bookmarkFavoritesJson BFS traversal (8 max)
    - currentTheme from Interface/PrometheusThemeDark setting
    - navigateTo scheme-validated (http/https only)
  affects:
    - falkon/src/lib/agent/prometheusstartbridge.h
    - falkon/src/lib/agent/prometheusstartbridge.cpp
    - falkon/src/lib/agent/agentruntimesidebar.h
    - falkon/src/lib/agent/agentruntimesidebar.cpp
    - falkon/src/lib/webengine/javascript/externaljsobject.cpp
    - falkon/src/lib/CMakeLists.txt
tech_stack:
  added:
    - PrometheusStartBridge QObject (QWebChannel bridge) for falkon:start
  patterns:
    - URL guard in setupWebChannel checking both page->url() and page->requestedUrl() against QUrl("falkon:start")
    - BFS bookmark traversal (QList<BookmarkItem*> queue) collecting up to 8 URL items
    - Deterministic warm-color mapping via qHash(host) % pool.size()
    - SideBar widget retrieval via sb->layout()->itemAt(1)->widget() cast to AgentRuntimeSidebarWidget
key_files:
  created:
    - falkon/src/lib/agent/prometheusstartbridge.h
    - falkon/src/lib/agent/prometheusstartbridge.cpp
  modified:
    - falkon/src/lib/agent/agentruntimesidebar.h
    - falkon/src/lib/agent/agentruntimesidebar.cpp
    - falkon/src/lib/webengine/javascript/externaljsobject.cpp
    - falkon/src/lib/CMakeLists.txt
decisions:
  - SideBarManager is declared in sidebar.h (no separate sidebarmanager.h file); include sidebar.h only
  - BrowserWindow obtained from WebPage via qobject_cast<TabbedWebView*>(page->view())->browserWindow() (nullptr-safe)
  - seedPromptAndOpen placed as public Q_SLOTS on AgentRuntimeSidebarWidget; no auto-submit (zero submitTask/runTask references)
  - openAgentWithPrompt handles both "already open" and "not yet open" sidebar states to avoid creating duplicate widgets
metrics:
  duration: 15min
  completed: "2026-06-17T09:15:00Z"
  tasks: 2
  files: 6
requirements: [START-02, START-03, START-04]
---

# Phase 10 Plan 03: PrometheusStartBridge and QWebChannel Registration Summary

## What Was Built

Wired the native C++ backend for the `falkon:start` page by creating `PrometheusStartBridge` and
integrating it with `ExternalJsObject::setupWebChannel` under a URL guard.

**`PrometheusStartBridge`** (new QObject bridge, `prometheusstartbridge.h/.cpp`):
- `openAgentWithPrompt(prompt)` — shows the PrometheusAgent sidebar and seeds the FSB Agent
  composer via `seedPromptAndOpen`; handles both "sidebar already open" and "sidebar closed"
  cases to prevent duplicate widget creation; zero auto-submit calls.
- `navigateTo(url)` — scheme-validated navigation: only `http` and `https` are allowed;
  `javascript:`, `data:`, `falkon:`, `file:`, and all other schemes are silently rejected.
- `bookmarkFavoritesJson()` — BFS traversal of the bookmark tree collecting up to 8 URL items,
  returning a compact JSON array with id, name, url, mono (host prefix), and a deterministic
  warm-accent color keyed by `qHash(host) % 5`.
- `currentTheme()` — reads `Interface/PrometheusThemeDark` setting (default `true`) and returns
  `"dark"` or `"light"`.

**`AgentRuntimeSidebarWidget::seedPromptAndOpen`** (new public slot):
- Sets `m_taskPrompt->setPlainText(prompt)` and `m_modeStack->setCurrentIndex(0)` (FSB Agent mode).
- Does NOT call `AgentRuntime::submitTask` or any auto-run path.

**`ExternalJsObject::setupWebChannel`** (modified):
- After the existing `qz_object` registration, conditionally registers `PrometheusStartBridge` as
  `qz_prometheus_start` only when `page->url() == QUrl("falkon:start")` OR
  `page->requestedUrl() == QUrl("falkon:start")`.
- `BrowserWindow*` is obtained safely via `qobject_cast<TabbedWebView*>(page->view())`.

**CMakeLists.txt**: `agent/prometheusstartbridge.cpp` and `agent/prometheusstartbridge.h` added to
`SOURCES` and `HEADERS` lists respectively, immediately after the existing `prometheusmarkwidget` entries.

## Verification Results

- `grep -rn "qz_prometheus_start" falkon/src/` — 2 occurrences: registration in `externaljsobject.cpp`
  and consumption in `start.html`. Confirmed.
- `grep -n "submitTask\|runTask" falkon/src/lib/agent/prometheusstartbridge.cpp` — 0 matches. Confirmed.
- `grep "scheme()" falkon/src/lib/agent/prometheusstartbridge.cpp` — present (`qurl.scheme() != QL1S("http") && qurl.scheme() != QL1S("https")`). Confirmed.
- `cmake --build falkon/build/fsb-baseline --target FalkonPrivate -j4` — exit 0 (no errors from any modified or new file; only pre-existing unrelated warnings).

## Commits

- `ae4db34b8` (falkon): `feat(10-03): add PrometheusStartBridge and seedPromptAndOpen slot`
- `ab14cdaa6` (falkon): `feat(10-03): register qz_prometheus_start bridge in setupWebChannel with URL guard`

## Deviations from Plan

**1. [Rule 3 - Blocking] sidebarmanager.h does not exist**
- **Found during:** Task 1 (build attempt)
- **Issue:** The plan's include list specified `sidebarmanager.h`, but `SideBarManager` is declared
  inside `sidebar.h` — there is no separate `sidebarmanager.h` in the codebase.
- **Fix:** Removed `sidebarmanager.h` include; `sidebar.h` already provides `SideBarManager`.
- **Files modified:** `falkon/src/lib/agent/prometheusstartbridge.cpp`
- **Commit:** `ab14cdaa6` (fix included in the second commit)

**2. [Rule 3 - Blocking] WebPage does not expose browserWindow()**
- **Found during:** Task 2 (reading WebPage header)
- **Issue:** The plan said `page->browserWindow()` but `WebPage` has no such method.
- **Fix:** Used `qobject_cast<TabbedWebView*>(page->view())->browserWindow()` — the same pattern
  used internally in `webpage.cpp` line 530-531. Added `tabbedwebview.h` include.
- **Files modified:** `falkon/src/lib/webengine/javascript/externaljsobject.cpp`
- **Commit:** `ab14cdaa6`

## Known Stubs

None. All four bridge methods are fully implemented with real data sources.

## Threat Surface Scan

Three trust boundaries introduced by this plan, per the plan's threat model:

| Flag | File | Description |
|------|------|-------------|
| T-10-07 mitigated | externaljsobject.cpp | URL guard: `qz_prometheus_start` registered only when `page->url() == QUrl("falkon:start")` OR `page->requestedUrl() == QUrl("falkon:start")` — both checked. Arbitrary pages cannot obtain the bridge. |
| T-10-08 mitigated | prometheusstartbridge.cpp | `navigateTo`: scheme validated before load; `javascript:`, `data:`, `falkon:`, `file:`, and any non-http/https scheme are silently rejected at `qurl.scheme()` check. |
| T-10-09 mitigated | prometheusstartbridge.cpp + agentruntimesidebar.cpp | `openAgentWithPrompt` → `seedPromptAndOpen`: only calls `setPlainText` and `setCurrentIndex(0)`. Zero `submitTask`/`runTask` references in `prometheusstartbridge.cpp`. Human must press Run Task. |
| T-10-10 accepted | externaljsobject.cpp | Post-load redirect: QWebChannel bridge is per-page-load; if the page navigates away the channel is destroyed with it. QtWebEngine isolation handles this. |

## Self-Check: PASSED

- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/prometheusstartbridge.h` — FOUND
- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/prometheusstartbridge.cpp` — FOUND
- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentruntimesidebar.h` (seedPromptAndOpen) — FOUND
- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/agent/agentruntimesidebar.cpp` (seedPromptAndOpen impl) — FOUND
- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/webengine/javascript/externaljsobject.cpp` (qz_prometheus_start) — FOUND
- `/Users/lakshman/conductor/workspaces/prometheus/puebla/falkon/src/lib/CMakeLists.txt` (prometheusstartbridge entries) — FOUND
- Commit `ae4db34b8` — confirmed in `git log --oneline -5`
- Commit `ab14cdaa6` — confirmed in `git log --oneline -5`
- Build exit 0 — confirmed (`cmake --build ... | grep error:` returned only pre-existing unrelated warnings)
