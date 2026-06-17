# Phase 10: New Tab Start Page — Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 7 new/modified files
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `falkon/src/lib/data/html/start.html` | HTML resource (new-tab surface) | request-response | `falkon/src/lib/data/html/start.html` (current) + `speeddial.html` | exact (replace) |
| `falkon/src/lib/agent/prometheusstartbridge.h` | QObject bridge (service) | request-response (JS-to-C++) | `falkon/src/lib/webengine/javascript/externaljsobject.h` | role-match |
| `falkon/src/lib/agent/prometheusstartbridge.cpp` | QObject bridge (service) | request-response | `falkon/src/lib/webengine/javascript/externaljsobject.cpp` + `agentruntimesidebar.cpp` | role-match |
| `falkon/src/lib/webengine/javascript/externaljsobject.cpp` | bridge registration (modify) | request-response | itself (modify `setupWebChannel`) | exact |
| `falkon/src/lib/agentruntimesidebar.h` | sidebar widget (modify) | event-driven | itself (add `seedPromptAndOpen` slot) | exact |
| `falkon/src/lib/network/schemehandlers/falkonschemehandler.cpp` | scheme handler (modify) | request-response | itself (`startPage()` method) | exact |
| `falkon/src/lib/tabwidget/tabwidget.cpp` | settings default (modify) | config | itself (line 176) | exact |
| `falkon/src/lib/data/icons.qrc` | Qt resource (modify) | config | itself | exact |

---

## Pattern Assignments

### `falkon/src/lib/data/html/start.html` (HTML resource, request-response)

**Analog:** `falkon/src/lib/data/html/start.html` (current, lines 1-48) and `falkon/src/lib/data/html/speeddial.html` (lines 1-10, JS channel pattern)

**Template token pattern** (from current `start.html` lines 1-48 and `falkonschemehandler.cpp` lines 151-172):

The existing `start.html` uses `%PLACEHOLDER%` tokens that `FalkonSchemeReply::startPage()` replaces
via `sPage.replace(QLatin1String("%TOKEN%"), value)`. The new start page must keep the `%PRIVATE-BROWSING%`
token (line 38 of current `start.html`) because `startPage()` already injects it. Drop all other
current tokens; replace the rest of the HTML with the Prometheus design.

Token to keep:
```html
%PRIVATE-BROWSING%
```

**`qrc:` URL pattern for resources in HTML** (from `speeddial.html` lines 7-10):
```html
html {
    background: url("%IMG_BACKGROUND%") no-repeat center center, url("qrc:html/sd_bg.svg");
}
```
All Qt resource assets referenced from HTML use `qrc:` URLs. For fonts that are `.ttf` files in
`falkon/src/lib/data/fonts/`, the `qrc:` prefix is `qrc:fonts/poppins/Poppins-Thin.ttf`. For the
SVG icons in `data/icons/fa/`, it is `qrc:icons/fa/bolt.svg`.

**Font face declarations for offline fonts** (pattern to write from scratch, matching resource paths in `fonts.qrc` lines 4-12):
```css
@font-face {
    font-family: 'Poppins';
    font-weight: 100;
    src: url('qrc:fonts/poppins/Poppins-Thin.ttf') format('truetype');
}
@font-face {
    font-family: 'Poppins';
    font-weight: 300;
    src: url('qrc:fonts/poppins/Poppins-Light.ttf') format('truetype');
}
@font-face {
    font-family: 'Poppins';
    font-weight: 800;
    src: url('qrc:fonts/poppins/Poppins-ExtraBold.ttf') format('truetype');
}
@font-face {
    font-family: 'Poppins';
    font-weight: 900;
    src: url('qrc:fonts/poppins/Poppins-Black.ttf') format('truetype');
}
@font-face {
    font-family: 'Space Mono';
    font-weight: 400;
    src: url('qrc:fonts/spacemono/SpaceMono-Regular.ttf') format('truetype');
}
```
Resource paths match `falkon/src/lib/data/fonts.qrc` exactly (lines 4-12).

**QWebChannel JS bootstrap pattern** (from `speeddial.html` data-initial-script attribute and restore.user.js pattern):

The start page must load qtwebchannel.js and initialise the bridge before DOM interaction:
```html
<script src="qrc:///qtwebchannel/qwebchannel.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function() {
    if (typeof qt === 'undefined' || !qt.webChannelTransport) {
        showBridgeError();
        return;
    }
    new QWebChannel(qt.webChannelTransport, function(channel) {
        var bridge = channel.objects.qz_prometheus_start;
        if (!bridge) { showBridgeError(); return; }
        initPage(bridge);
    });
    // Timeout fallback: if bridge not available in 2 s, show error state
    setTimeout(function() {
        if (!window._bridgeReady) { showBridgeError(); }
    }, 2000);
});
</script>
```

**FA icon usage in HTML** — CRITICAL: FA icons in this codebase are SVG files, NOT a web font.
There are no `.woff2` files bundled. The `icons.qrc` bundles SVGs at `qrc:icons/fa/*.svg`.
Use `<img>` tags, not `<i class="fa ...">`:
```html
<img src="qrc:icons/fa/magnifying-glass.svg" class="q" aria-hidden="true">
<img src="qrc:icons/fa/bolt.svg" aria-hidden="true"> Ask FSB
```

**Missing FA icons for suggestion cards** — `fa-inbox`, `fa-cart-shopping`, and `fa-calendar-check`
are NOT in the bundled `icons.qrc` set (verified: no such files exist in
`falkon/src/lib/data/icons/fa/`). These three SVGs must be:
1. Downloaded from Font Awesome Free 6.x (CC BY 4.0)
2. Added to `falkon/src/lib/data/icons/fa/`
3. Registered in `falkon/src/lib/data/icons.qrc`

**PM mark CSS replica** (derived from `prometheusmarkwidget.cpp` lines 44-137):

The native `PrometheusMarkWidget(Medium)` draws P (Poppins Thin 100, 26px) + M (Poppins Black 900, 26px)
centered in a 64x64 area, with a version tag `▽0.1` in Space Mono below. The CSS replica:
```css
.pm-hero-mark {
    width: 64px;
    height: 64px;
    border-radius: 18px;
    background: linear-gradient(135deg, #ff6b35, #ff8c42);
    display: grid;
    place-items: center;
    box-shadow: var(--shadow-card);
    font-family: 'Poppins', sans-serif;
    font-size: 26px;
    color: #ffffff;
    /* P = Thin 100, M = Black 900 — use two spans */
}
.pm-hero-mark .lp { font-weight: 100; }
.pm-hero-mark .lm { font-weight: 900; }
```
HTML: `<div class="pm-hero-mark"><span class="lp">P</span><span class="lm">M</span></div>`

**Theme data attribute pattern**:
```html
<html data-theme="dark">
```
JS sets on DOMContentLoaded via bridge:
```js
bridge.currentTheme(function(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    window._bridgeReady = true;
});
```
CSS uses `[data-theme="dark"]` and `[data-theme="light"]` selectors to switch token values.

---

### `falkon/src/lib/agent/prometheusstartbridge.h` (QObject bridge, request-response)

**Analog:** `falkon/src/lib/webengine/javascript/externaljsobject.h` (lines 30-54)

**Header pattern** (from `externaljsobject.h` lines 30-54):
```cpp
#ifndef PROMETHEUSSTARTBRIDGE_H
#define PROMETHEUSSTARTBRIDGE_H

#include "qzcommon.h"
#include <QObject>

class BrowserWindow;

class FALKON_EXPORT PrometheusStartBridge : public QObject
{
    Q_OBJECT
public:
    explicit PrometheusStartBridge(BrowserWindow* window, QObject* parent = nullptr);

public Q_SLOTS:
    void openAgentWithPrompt(const QString& prompt);
    void navigateTo(const QString& url);
    QString bookmarkFavoritesJson() const;
    QString currentTheme() const;

private:
    BrowserWindow* m_window;
};

#endif // PROMETHEUSSTARTBRIDGE_H
```

Note: slots callable from QWebChannel must be `Q_SLOTS` (not private). `Q_INVOKABLE` is acceptable
for read-only queries (`currentTheme`, `bookmarkFavoritesJson`) but `Q_SLOTS` is the pattern used
in the existing codebase (`ExternalJsObject` properties map to slots via Q_PROPERTY in the analog).

---

### `falkon/src/lib/agent/prometheusstartbridge.cpp` (QObject bridge, request-response)

**Analog 1:** `falkon/src/lib/webengine/javascript/externaljsobject.cpp` lines 30-85 — QObject constructor and slot structure

**Analog 2:** `falkon/src/lib/agent/agentruntimesidebar.cpp` lines 464-509 — bookmark traversal pattern for `bookmarkFavoritesJson`; lines 352-390 — `runTask` shows how to access sidebar widget

**Imports pattern** (from `agentruntimesidebar.cpp` lines 1-37):
```cpp
#include "prometheusstartbridge.h"
#include "agentruntimesidebar.h"
#include "bookmarkitem.h"
#include "bookmarks.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "sidebarmanager.h"
#include "tabbedwebview.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
```

**`openAgentWithPrompt` implementation pattern** — derived from how `agentruntimesidebar.cpp`
line 342 switches mode stack and `sidebar.cpp` lines 173-216 show `showSideBar`:
```cpp
void PrometheusStartBridge::openAgentWithPrompt(const QString& prompt)
{
    if (!m_window) return;

    // 1. Show the sidebar (non-toggle: false means "show, do not close if open")
    m_window->sideBarManager()->showSideBar(QSL("PrometheusAgent"), false);

    // 2. Retrieve the active AgentRuntimeSidebarWidget and seed the prompt
    //    SideBarManager::showSideBar creates the widget via createSideBarWidget —
    //    retrieve it from the SideBar's current widget.
    SideBar* sideBar = m_window->sideBar();
    if (sideBar) {
        AgentRuntimeSidebarWidget* w =
            qobject_cast<AgentRuntimeSidebarWidget*>(sideBar->widget());
        if (w) {
            w->seedPromptAndOpen(prompt);
        }
    }
}
```

**`bookmarkFavoritesJson` implementation pattern** (from `agentruntimesidebar.cpp` `refreshExplorer` lines 464-487):
```cpp
QString PrometheusStartBridge::bookmarkFavoritesJson() const
{
    QJsonArray result;
    BookmarkItem* root = mApp->bookmarks()->rootItem();
    QList<BookmarkItem*> queue = root->children();
    int count = 0;
    while (!queue.isEmpty() && count < 8) {
        BookmarkItem* item = queue.takeFirst();
        if (item->isUrl()) {
            const QString host = item->url().host();
            const QString mono = host.left(2).toUpper();
            QJsonObject obj;
            obj[QSL("id")]    = QSL("bm-%1").arg(count);
            obj[QSL("name")]  = item->title();
            obj[QSL("url")]   = item->urlString();
            obj[QSL("mono")]  = mono;
            obj[QSL("color")] = deterministicColor(host);
            result.append(obj);
            ++count;
        } else if (item->isFolder()) {
            queue.append(item->children());
        }
    }
    return QString::fromUtf8(QJsonDocument(result).toJson(QJsonDocument::Compact));
}
```
The `deterministicColor(host)` helper maps a host string to one of the warm accent pool values
(`#ff6b35`, `#d4824a`, `#a0522d`, `#7b5e4b`, `#5c4a3a`) by `qHash(host) % pool.size()`.

**`navigateTo` implementation pattern** (from `agentruntimesidebar.cpp` lines 267-272):
```cpp
void PrometheusStartBridge::navigateTo(const QString& url)
{
    if (m_window && m_window->weView()) {
        m_window->weView()->load(QUrl(url));
    }
}
```

**`currentTheme` implementation pattern** (from `mainapplication.cpp` line 1054):
```cpp
QString PrometheusStartBridge::currentTheme() const
{
    Settings settings;
    const bool dark = settings.value(QSL("Interface/PrometheusThemeDark"), true).toBool();
    return dark ? QSL("dark") : QSL("light");
}
```

---

### `falkon/src/lib/webengine/javascript/externaljsobject.cpp` (modify, bridge registration)

**Analog:** itself — `setupWebChannel` lines 43-50

**Registration pattern** (from `externaljsobject.cpp` lines 43-50):
```cpp
// static
void ExternalJsObject::setupWebChannel(QWebChannel *webChannel, WebPage *page)
{
    webChannel->registerObject(QSL("qz_object"), new ExternalJsObject(page));

    for (auto it = s_extraObjects.constBegin(); it != s_extraObjects.constEnd(); ++it) {
        webChannel->registerObject(QSL("qz_") + it.key(), it.value());
    }
}
```

**Modification:** Add conditional registration immediately after the existing `registerObject` call:
```cpp
    // Register start-page bridge when loading falkon:start
    if (page->url() == QUrl(QSL("falkon:start"))
        || page->requestedUrl() == QUrl(QSL("falkon:start"))) {
        webChannel->registerObject(QSL("qz_prometheus_start"),
                                   new PrometheusStartBridge(page->browserWindow(), webChannel));
    }
```

This mirrors the existing `speedDial()` URL guard pattern at `externaljsobject.cpp` lines 64-72:
```cpp
QObject *ExternalJsObject::speedDial() const
{
    if (m_page->url().toString() != QL1S("falkon:speeddial")
      && (m_page->requestedUrl().toString() != QL1S("falkon:speeddial") && !m_page->url().toString().isEmpty())) {
        return nullptr;
    }
    return mApp->plugins()->speedDial();
}
```

---

### `falkon/src/lib/agent/agentruntimesidebar.h` (modify, add slot)

**Analog:** itself — class definition lines 30-88

**Slot to add** (per `10-UI-SPEC.md` lines 99-106):
```cpp
// In the public Q_SLOTS section of AgentRuntimeSidebarWidget:
public Q_SLOTS:
    void seedPromptAndOpen(const QString& prompt);
```

**`seedPromptAndOpen` implementation** (derived from `buildFsbAgentPage` lines 182-226 which shows `m_taskPrompt` and `m_modeStack`):
```cpp
void AgentRuntimeSidebarWidget::seedPromptAndOpen(const QString& prompt)
{
    if (m_taskPrompt) {
        m_taskPrompt->setPlainText(prompt);
    }
    if (m_modeStack) {
        m_modeStack->setCurrentIndex(0);  // index 0 = FSB Agent mode
    }
}
```
The method sets `m_taskPrompt` (QPlainTextEdit, line 200 of `agentruntimesidebar.cpp`) and
switches `m_modeStack` (QStackedWidget, line 149) to index 0 (FSB Agent page, line 151-153).
It does NOT call `AgentRuntime::submitTask` — prompt is staged only, not auto-submitted.

---

### `falkon/src/lib/network/schemehandlers/falkonschemehandler.cpp` (modify, `startPage()`)

**Analog:** itself — `startPage()` lines 151-172, `speeddialPage()` lines 211-267

**Current `startPage()` pattern** (lines 151-172):
```cpp
QString FalkonSchemeReply::startPage()
{
    static QString sPage;

    if (!sPage.isEmpty()) {
        return sPage;
    }

    sPage.append(QzTools::readAllFileContents(QSL(":html/start.html")));
    sPage.replace(QLatin1String("%ABOUT-IMG%"), QSL("qrc:icons/prometheus.svg"));
    sPage.replace(QLatin1String("%ABOUT-IMG-DARK%"), QSL("qrc:icons/prometheus.svg"));
    sPage.replace(QLatin1String("%TITLE%"), tr("Start Page"));
    sPage.replace(QLatin1String("%BUTTON-LABEL%"), tr("Search on Web"));
    sPage.replace(QLatin1String("%SEARCH-BY%"), tr("Powered by FSB"));
    sPage.replace(QLatin1String("%WWW%"), QString::fromLatin1(Qz::WIKIADDRESS));
    sPage.replace(QLatin1String("%ABOUT-FALKON%"), tr("About Prometheus"));
    sPage.replace(QLatin1String("%PRIVATE-BROWSING%"), mApp->isPrivate() ? tr("<h1>Private Browsing</h1>") : QString());
    sPage = QzTools::applyDirectionToPage(sPage);
    return sPage;
}
```

**Replacement:** The new `start.html` is self-contained HTML/CSS/JS. The `startPage()` method
simplifies to:
```cpp
QString FalkonSchemeReply::startPage()
{
    static QString sPage;
    if (!sPage.isEmpty()) {
        return sPage;
    }
    sPage.append(QzTools::readAllFileContents(QSL(":html/start.html")));
    sPage.replace(QLatin1String("%TITLE%"), tr("New Tab"));
    sPage.replace(QLatin1String("%PRIVATE-BROWSING%"), mApp->isPrivate()
        ? QSL("<div class=\"pm-private-notice\">%1</div>").arg(tr("Private Browsing"))
        : QString());
    sPage = QzTools::applyDirectionToPage(sPage);
    return sPage;
}
```

The static caching pattern (check `!sPage.isEmpty()` before rebuilding) must be preserved because
`speeddialPage()` shows a two-stage pattern: static tokens replaced once, then per-request tokens
replaced on each call (lines 253-266). For the start page, all tokens are static, so single-stage
caching is fine.

---

### `falkon/src/lib/tabwidget/tabwidget.cpp` (modify, default URL)

**Analog:** itself — line 176

**Current default** (line 176):
```cpp
m_urlOnNewTab = settings.value(QSL("newTabUrl"), QSL("falkon:speeddial")).toUrl();
```

**Change to:**
```cpp
m_urlOnNewTab = settings.value(QSL("newTabUrl"), QSL("falkon:start")).toUrl();
```

This is a one-line change. Existing user settings that have explicitly set `newTabUrl` are
preserved because `settings.value()` only falls back to the default when the key is absent.
Users who previously accepted the `falkon:speeddial` default automatically get `falkon:start`
only on a fresh profile. To migrate existing profiles, the preferences page or a one-time
migration in `TabWidget::loadSettings()` can write the new default — this is a planning decision,
not a pattern question.

---

### `falkon/src/lib/data/icons.qrc` (modify, add missing FA SVGs)

**Analog:** itself — lines 64-133 (Font Awesome subset block)

**Pattern for new entries** (from icons.qrc lines 64-68):
```xml
<!-- Font Awesome Free 6.x subset — CC BY 4.0 — offline only -->
<file>icons/fa/arrow-left.svg</file>
<file>icons/fa/arrow-right.svg</file>
```

**Three entries to add** for suggestion card icons (files must also be downloaded):
```xml
<file>icons/fa/inbox.svg</file>
<file>icons/fa/cart-shopping.svg</file>
<file>icons/fa/calendar-check.svg</file>
```

Source: Font Awesome Free 6.x, solid style, CC BY 4.0. Download the SVG files from
`https://github.com/FortAwesome/Font-Awesome/tree/6.x/svgs/solid/` and place them in
`falkon/src/lib/data/icons/fa/`.

---

## Shared Patterns

### QWebChannel bridge registration
**Source:** `falkon/src/lib/webengine/javascript/externaljsobject.cpp` lines 43-50
**Apply to:** `prometheusstartbridge.cpp`, `externaljsobject.cpp` modification

Pattern: `webChannel->registerObject(QSL("qz_<name>"), objectPointer)`. The `qz_` prefix is
the project-wide convention for all bridge objects. The start bridge uses `qz_prometheus_start`.

### URL guard for page-specific bridge objects
**Source:** `falkon/src/lib/webengine/javascript/externaljsobject.cpp` lines 64-72
**Apply to:** `externaljsobject.cpp` modification

Pattern: check `m_page->url()` and `m_page->requestedUrl()` (both checked because during load the
url() may still reflect the previous page). Only register or return the bridge object when on the
correct `falkon:` URL.

### Bookmark tree traversal (BFS)
**Source:** `falkon/src/lib/agent/agentruntimesidebar.cpp` lines 464-487
**Apply to:** `prometheusstartbridge.cpp` `bookmarkFavoritesJson`

Pattern: `QList<BookmarkItem*> queue = root->children(); while (!queue.isEmpty()) { auto item = queue.takeFirst(); if (item->isUrl()) { ... } else if (item->isFolder()) { queue.append(item->children()); } }`

### Navigate current tab from C++
**Source:** `falkon/src/lib/agent/agentruntimesidebar.cpp` lines 267-272
**Apply to:** `prometheusstartbridge.cpp` `navigateTo`

Pattern: `m_window->weView()->load(QUrl(url))`

### Settings read (PrometheusThemeDark key)
**Source:** `falkon/src/lib/app/mainapplication.cpp` line 1054
**Apply to:** `prometheusstartbridge.cpp` `currentTheme`

Pattern: `Settings settings; settings.value(QSL("Interface/PrometheusThemeDark"), true).toBool()`

### `qrc:` font URLs in HTML
**Source:** `falkon/src/lib/data/fonts.qrc` lines 4-12
**Apply to:** `start.html` `@font-face` declarations

Exact paths: `qrc:fonts/poppins/Poppins-Thin.ttf`, `qrc:fonts/poppins/Poppins-Light.ttf`,
`qrc:fonts/poppins/Poppins-ExtraBold.ttf`, `qrc:fonts/poppins/Poppins-Black.ttf`,
`qrc:fonts/spacemono/SpaceMono-Regular.ttf`.

### FA icon usage in HTML (SVG img, not web font)
**Source:** `falkon/src/lib/data/icons.qrc` lines 64-133, all `.svg` files
**Apply to:** `start.html` everywhere a FA icon appears

Pattern: `<img src="qrc:icons/fa/<name>.svg" aria-hidden="true">`. Do NOT use `<i class="fa ...">` —
there is no Font Awesome web font bundle in this codebase; icons are individual SVGs only.

---

## No Analog Found

No files without analogs. All patterns have direct counterparts in the existing Falkon/Prometheus codebase.

---

## Critical Planning Notes for Planner

1. **FA SVG color in HTML**: The bundled FA SVGs render at the browser's default color (typically
   black or system foreground). To apply `var(--accent)` color to suggestion card icons, use CSS
   filter: `img.card-icon { filter: invert(45%) sepia(90%) saturate(700%) hue-rotate(340deg) brightness(100%); }`
   or embed the SVG inline and set `fill: var(--accent)`. The `filter` approach is simpler for
   HTML resources; the inline SVG approach is more robust.

2. **`showSideBar` creates a new widget on each call**: `SideBarManager::showSideBar` (sidebar.cpp
   line 211) calls `sidebar->createSideBarWidget(m_window)` which creates a fresh
   `AgentRuntimeSidebarWidget`. If the sidebar is already open and active, the `id == m_activeBar`
   guard at line 187 returns early without creating a new widget. `PrometheusStartBridge::openAgentWithPrompt`
   must retrieve the existing widget from the open sidebar, not create a new one. Use
   `m_window->sideBar()->widget()` — but the `SideBar` accessor on `BrowserWindow` needs to be
   checked; the alternate approach is to call `seedPromptAndOpen` before `showSideBar` if the
   sidebar is already open.

3. **Static page caching in `startPage()`**: The existing `startPage()` uses a `static QString sPage`
   that is built once and never rebuilt. The private-browsing token (`%PRIVATE-BROWSING%`) is
   substituted into the cached string. This means a non-private window caching an empty string
   will serve that empty string to a later private window in the same process. The `speeddialPage()`
   pattern (lines 253-266) solves this by having a two-stage cache: static tokens built once into
   `dPage`, then per-request tokens replaced into a copy (`QString page = dPage`). The new
   `startPage()` should follow the same two-stage pattern for the `%PRIVATE-BROWSING%` token.

4. **Missing icons must be added before HTML can be written**: The `fa-inbox`, `fa-cart-shopping`,
   and `fa-calendar-check` SVGs must be added to `data/icons/fa/` and `icons.qrc` as part of this
   phase. This is a blocking dependency for `start.html`.

---

## Metadata

**Analog search scope:** `falkon/src/lib/`
**Files scanned:** 15 source files read directly; ~30 additional grep/glob passes
**Pattern extraction date:** 2026-06-17
