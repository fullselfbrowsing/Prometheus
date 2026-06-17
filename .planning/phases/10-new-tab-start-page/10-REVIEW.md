---
phase: 10-new-tab-start-page
reviewed: 2026-06-17T00:00:00Z
depth: deep
files_reviewed: 6
files_reviewed_list:
  - src/lib/agent/prometheusstartbridge.cpp
  - src/lib/agent/prometheusstartbridge.h
  - src/lib/agent/agentruntimesidebar.cpp
  - src/lib/agent/agentruntimesidebar.h
  - src/lib/data/html/start.html
  - src/lib/network/schemehandlers/falkonschemehandler.cpp
  - src/lib/tabwidget/tabwidget.cpp
  - src/lib/webengine/javascript/externaljsobject.cpp
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
status: partially_resolved
---

# Phase 10: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** deep
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Phase 10 introduces the `falkon:start` new-tab page with a QWebChannel bridge (`PrometheusStartBridge`),
a sidebar seeding slot in `AgentRuntimeSidebarWidget`, and a two-stage template cache in
`FalkonSchemeReply::startPage()`.

The web-to-native trust boundary is structurally sound in intent: `navigateTo()` rejects
non-http/https schemes, `openAgentWithPrompt()` has no auto-run path, and
`bookmarkFavoritesJson()` returns a bounded JSON payload. However, one BLOCKER functional
bug means the bridge is unreachable from every normally-opened new tab, and one WARNING-level
XSS exists in the favorites tile `title=` attribute that would become exploitable the moment
the bridge bug is fixed.

---

## Critical Issues

### CR-01: URL guard evaluated at WebPage construction — bridge never registered for normal new tabs

**File:** `src/lib/webengine/javascript/externaljsobject.cpp:52-53`

**Issue:** `setupWebChannel()` is called in `WebPage::WebPage()` (webpage.cpp:89), before any
navigation has started. At that point `page->url()` and `page->requestedUrl()` are both `QUrl()`
(empty). The guard

```cpp
if (page->url() == QUrl(QSL("falkon:start"))
        || page->requestedUrl() == QUrl(QSL("falkon:start")))
```

evaluates to `false` for every WebPage constructed via the normal tab path
(`WebTab::WebTab()` → `m_webView->setPage(new WebPage)` → later `webTab->webView()->load(falkon:start)`).
`QWebChannel::registerObject` is a one-time call — it cannot be deferred or re-run after navigation.
The consequence is that `qz_prometheus_start` is never present in the channel for any ordinarily
opened new tab. The page's `DOMContentLoaded` handler then falls through to `showBridgeError()` and
hides the Ask FSB button. The entire start-page feature is inert.

The parallel with `speedDial()` cited in the comment does not apply: `speedDial()` is a
`Q_INVOKABLE` method checked on every JS call against the live `page->url()`, not a one-time
registration predicate.

**Fix:** Two viable approaches:

**Option A (preferred) — register unconditionally, add per-slot URL check:**
```cpp
// externaljsobject.cpp — setupWebChannel
BrowserWindow* bw = qobject_cast<TabbedWebView*>(page->view())
                        ? qobject_cast<TabbedWebView*>(page->view())->browserWindow()
                        : nullptr;
// Register unconditionally; each slot in PrometheusStartBridge checks the calling page URL.
webChannel->registerObject(QSL("qz_prometheus_start"),
                           new PrometheusStartBridge(bw, page, webChannel));
```

```cpp
// prometheusstartbridge.cpp — add guard in each public slot
void PrometheusStartBridge::openAgentWithPrompt(const QString& prompt)
{
    if (!m_page || m_page->url() != QUrl(QSL("falkon:start"))) { return; }
    // ... existing logic
}
```
Store `WebPage* m_page` (set in constructor, raw pointer is safe because the bridge is
owned by the QWebChannel which is owned by the WebPage — they die together).

**Option B — lazy registration on first committed URL:**
Connect to `QWebEnginePage::urlChanged` and call `webChannel->registerObject` once when the
URL first becomes `falkon:start`. Note Qt docs warn against registering objects after the
channel is attached, so this needs testing.

---

## Warnings

### WR-01: XSS via bookmark title in `title=""` attribute — incomplete HTML escaping

**File:** `src/lib/data/html/start.html:544,551`

**Issue:** `safeName` escapes `<` and `>` but not `"`. It is injected into a double-quoted
HTML attribute:

```js
var safeName = item.name ? item.name.replace(/</g, '&lt;').replace(/>/g, '&gt;') : '';
// ...
' title="' + safeName + '">'
```

A bookmark named `x" onclick="window._bridge.navigateTo('https://attacker.com')` produces:

```html
<button class="pm-fav-tile" tabindex="0" data-url="…" title="x" onclick="window._bridge.navigateTo('https://attacker.com')">
```

Bookmark titles come from the user's own bookmark database, which can be populated via
OPML/HTML bookmark import from an untrusted file. On `falkon:start`, when the bridge
registration bug (CR-01) is fixed, this grants the injected handler access to the bridge.
Even today the XSS executes arbitrary JS on `falkon:start`.

**Fix:**
```js
var safeName = item.name
    ? item.name
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&#39;')
    : '';
```
Apply the same full-attribute-escape to `safeMono` (used in `style="background:…"` element
content, low risk in practice but should be consistent).

---

### WR-02: `m_window` is a raw pointer — potential use-after-free if BrowserWindow closes during async bridge callback

**File:** `src/lib/agent/prometheusstartbridge.cpp:58-59`, `prometheusstartbridge.h:39`

**Issue:** `m_window` is `BrowserWindow*` (raw pointer). `PrometheusStartBridge` is parented
to `QWebChannel` → `WebPage` → `WebTab` → `BrowserWindow`. In the normal Qt object tree this
means the bridge is destroyed when the window closes, so the lifetime looks safe. However,
QWebChannel slots are dispatched via the Qt event loop from IPC demultiplexing; if a
browser window closes (destroying the bridge's parent chain) while a transport message is
in-flight and queued in the event loop, `m_window` will dangle during the eventual slot
invocation. The null-check `if (!m_window)` does not protect against a freed pointer.

**Fix:**
```cpp
// prometheusstartbridge.h
#include <QPointer>
// ...
QPointer<BrowserWindow> m_window;
```
`QPointer` zeroes itself when the pointed-to QObject is destroyed, making the existing
null check safe.

---

### WR-03: BFS bookmark queue unbounded — no cap on queue depth, only on output count

**File:** `src/lib/agent/prometheusstartbridge.cpp:111-129`

**Issue:** The loop terminates when `count >= 8` (URL items emitted) or the queue is
exhausted. The queue itself is unbounded: a bookmark tree that is entirely folders with
no URL items (or URLs nested very deep) will enqueue all folder children recursively
before the loop exits. With a pathologically large imported bookmark set (tens of thousands
of nested folders and no bookmarks at the top levels), this allocates a very large
`QList<BookmarkItem*>` on the heap before returning an empty result.

**Fix:** Add a visited-node cap:

```cpp
int visited = 0;
const int kMaxVisit = 2000;
while (!queue.isEmpty() && count < 8 && visited < kMaxVisit) {
    BookmarkItem* item = queue.takeFirst();
    ++visited;
    // ... rest of loop unchanged
}
```

---

## Info

### IN-01: Static `dPage` initialisation in `startPage()` is not thread-safe under Qt 6 scheme handler threading

**File:** `src/lib/network/schemehandlers/falkonschemehandler.cpp:154-159`

**Issue:** `requestStarted()` is documented to be called on the I/O thread in Qt 6.
Two concurrent requests for `falkon:start` can both observe `dPage.isEmpty() == true`
and both call `dPage.append(…)` and `dPage.replace(…)`, corrupting the cache with
doubled content or a partially-replaced template. The same pattern exists for `speeddialPage()`
and others (pre-existing), but Phase 10 adds a new instance.

Note: the per-request `page = dPage` copy and the `%PRIVATE-BROWSING%` substitution are
correctly done on a local variable — only the static initialisation is racy.

**Fix:**
```cpp
static QString dPage;
static std::once_flag dPageOnce;
std::call_once(dPageOnce, [&]() {
    dPage.append(QzTools::readAllFileContents(QSL(":html/start.html")));
    dPage.replace(QLatin1String("%TITLE%"), tr("New Tab"));
    dPage = QzTools::applyDirectionToPage(dPage);
});
```

---

## What Was Verified Clean

- **`navigateTo()` scheme allowlist** — correctly rejects `javascript:`, `data:`, `falkon:`,
  `file:`, etc. via `qurl.scheme() != "http" && != "https"` (prometheusstartbridge.cpp:99-101).

- **`openAgentWithPrompt()` no-auto-run** — the slot calls `seedPromptAndOpen()` which only
  sets text and switches mode stack index. No `submitTask`, `runTask`, or any agent invocation
  path is reachable from web content (agentruntimesidebar.cpp:182-190).

- **Two-stage private-browsing cache** — Stage 1 (`static dPage`) retains `%PRIVATE-BROWSING%`
  as a literal token; Stage 2 replaces it per-request on a local copy. No bleed between
  private and normal sessions (falkonschemehandler.cpp:151-167).

- **URL guard intent** — the registration guard (even though broken functionally per CR-01)
  is correctly positioned to prevent arbitrary https pages from obtaining the bridge, because
  those pages' WebPage objects are constructed at a URL that is not `falkon:start`.

- **`bookmarkFavoritesJson()` output-count cap** — the `count < 8` guard correctly limits
  the JSON payload to 8 items. Output is serialised via `QJsonDocument` with no manual
  string interpolation, so bookmark data cannot inject malformed JSON (prometheusstartbridge.cpp:130).

- **`deterministicColor()` modulo** — `qHash(host) % pool.size()` with a pool of 5 entries
  returns `[0, 4]` which is a valid index range; the `static_cast<int>` of a small unsigned
  value is safe (prometheusstartbridge.cpp:45).

- **`newTabUrl` default change** — the only change to `tabwidget.cpp` replaces the default
  value `"falkon:speeddial"` with `"falkon:start"`. Explicit user-saved settings are
  unaffected because `settings.value(key, default)` only falls back to the default when
  no value is stored (tabwidget.cpp:176).

- **Graceful degradation** — start.html correctly handles the bridge-absent case by
  checking `typeof qt === 'undefined'` before initialising QWebChannel and showing a
  bridge-error notice otherwise (start.html:687-689).

- **`seedPromptAndOpen()` sidebar no-auto-run** — sets `m_taskPrompt->setPlainText(prompt)`
  and switches the mode stack; does not call `runTask()` (agentruntimesidebar.cpp:182-190).

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
