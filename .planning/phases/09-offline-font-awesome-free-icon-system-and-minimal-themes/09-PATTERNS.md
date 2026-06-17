# Phase 9: Offline Font Awesome Free Icon System and Minimal Themes — Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `falkon/src/lib/data/icons.qrc` | config | resource-bundle | `falkon/src/lib/data/breeze-fallback.qrc` | exact |
| `falkon/src/lib/data/fonts.qrc` | config | resource-bundle | `falkon/src/lib/data/icons.qrc` | exact |
| `falkon/src/lib/agent/prometheusiconresolver.h/.cpp` | service | request-response | `falkon/src/lib/tools/iconprovider.h/.cpp` | role-match |
| `falkon/src/lib/agent/prometheusmarkwidget.h/.cpp` | component | request-response | `falkon/src/lib/agent/agentruntimesidebar.cpp` (header block) | role-match |
| `falkon/src/lib/app/mainapplication.cpp` (modified) | config | request-response | self — font registration block at line 150 | exact |
| `falkon/themes/prometheus/prometheus-dark.qss` | config | request-response | `falkon/themes/linux/main.css` | role-match |
| `falkon/themes/prometheus/prometheus-light.qss` | config | request-response | `falkon/themes/linux/main.css` | role-match |
| `falkon/themes/prometheus/prometheus-common.qss` | config | request-response | `falkon/themes/mac/main.css` | role-match |
| `falkon/themes/prometheus/metadata.desktop` | config | n/a | `falkon/themes/linux/metadata.desktop` | exact |

---

## Pattern Assignments

### `falkon/src/lib/data/icons.qrc` (modified — add FA SVG subset)

**Analog:** `falkon/src/lib/data/breeze-fallback.qrc`

The existing `icons.qrc` uses prefix `/` and stores icons under `icons/`. The new FA subset lives under prefix `/` with files at `icons/fa/`. The breeze-fallback file shows the per-size sub-directory pattern; FA SVGs are single files (not sized subdirs) so the flat naming wins.

**Existing QRC structure** (`falkon/src/lib/data/icons.qrc` lines 1-65):
```xml
<RCC>
    <qresource prefix="/">
        <file>icons/falkon.svg</file>
        <file>icons/prometheus.svg</file>
        <file>icons/menu/history.svg</file>
        <!-- ... more named icon paths ... -->
    </qresource>
</RCC>
```

**Breeze-fallback prefix pattern** (`falkon/src/lib/data/breeze-fallback.qrc` lines 1-35):
```xml
<RCC>
    <qresource prefix="/icons">
        <file>breeze-fallback/index.theme</file>
        <file>breeze-fallback/16x16/go-previous.svg</file>
        <!-- ... -->
    </qresource>
</RCC>
```

**Pattern to apply for FA subset — add inside existing `<qresource prefix="/">` block:**
```xml
        <!-- Font Awesome Free 6.x subset — CC BY 4.0 — offline only -->
        <file>icons/fa/arrow-left.svg</file>
        <file>icons/fa/arrow-right.svg</file>
        <file>icons/fa/rotate-right.svg</file>
        <file>icons/fa/xmark.svg</file>
        <file>icons/fa/house.svg</file>
        <file>icons/fa/plus.svg</file>
        <file>icons/fa/magnifying-glass.svg</file>
        <file>icons/fa/lock.svg</file>
        <file>icons/fa/lock-open.svg</file>
        <!-- ... full list per 09-UI-SPEC.md action-to-glyph map ... -->
```

**CMakeLists registration** (`falkon/src/lib/CMakeLists.txt` lines 613-618):
```cmake
qt_add_resources(SRCS
    data/data.qrc
    data/html.qrc
    data/icons.qrc          # already listed — no new line needed for FA additions
    data/breeze-fallback.qrc
    adblock/adblock.qrc
)
```

New `fonts.qrc` must be added as a new entry in the same `qt_add_resources` block.

---

### `falkon/src/lib/data/fonts.qrc` (new)

**Analog:** `falkon/src/lib/data/data.qrc` (simplest self-contained QRC)

**Pattern to copy** (`falkon/src/lib/data/data.qrc` lines 1-8):
```xml
<RCC>
    <qresource prefix="/">
        <file>data/bookmarks.json</file>
        <file>data/browsedata.sql</file>
    </qresource>
</RCC>
```

**New file should be:**
```xml
<RCC>
    <qresource prefix="/">
        <file>fonts/poppins/Poppins-Thin.ttf</file>
        <file>fonts/poppins/Poppins-Light.ttf</file>
        <file>fonts/poppins/Poppins-ExtraBold.ttf</file>
        <file>fonts/poppins/Poppins-Black.ttf</file>
        <file>fonts/spacemono/SpaceMono-Regular.ttf</file>
    </qresource>
</RCC>
```

Font files live in `falkon/src/lib/data/fonts/poppins/` and `falkon/src/lib/data/fonts/spacemono/` relative to the QRC file.

---

### `falkon/src/lib/agent/prometheusiconresolver.h/.cpp` (new — service, request-response)

**Analog:** `falkon/src/lib/tools/iconprovider.h/.cpp`

IconProvider is a singleton QWidget subclass providing static icon-fetch methods. PrometheusIconResolver follows the same singleton + static-method pattern but maps ActionId strings to bundled SVG resources instead of URLs to cached favicons.

**Header pattern** (`falkon/src/lib/tools/iconprovider.h` lines 38-88):
```cpp
class FALKON_EXPORT IconProvider : public QWidget
{
    Q_OBJECT
    Q_PROPERTY(QIcon bookmarkIcon READ bookmarkIcon WRITE setBookmarkIcon)

public:
    explicit IconProvider();

    // Static lookup methods
    static QIcon standardIcon(QStyle::StandardPixmap icon);
    static QIcon newTabIcon();
    static QIcon iconForUrl(const QUrl &url, bool allowNull = false);

    static IconProvider* instance();

private:
    // ...members...
};
```

**Singleton instantiation pattern** (`falkon/src/lib/tools/iconprovider.cpp` line 31):
```cpp
Q_GLOBAL_STATIC(IconProvider, qz_icon_provider)
```

**Pattern to apply — PrometheusIconResolver:**
```cpp
// prometheusiconresolver.h
class FALKON_EXPORT PrometheusIconResolver : public QObject
{
    Q_OBJECT

public:
    // Central lookup: tries :/icons/fa/{glyph}.svg, falls back to
    // QIcon::fromTheme(fallback), then returns 1x1 transparent + emits qWarning
    static QIcon icon(const QString &actionId);

    static PrometheusIconResolver* instance();

private:
    explicit PrometheusIconResolver(QObject* parent = nullptr);

    // action-id → {resourcePath, themeFallback} map
    static QHash<QString, QPair<QString,QString>> s_actionMap;
    static void initActionMap();
};
```

**Fallback chain to implement** (from 09-UI-SPEC.md):
```cpp
// prometheusiconresolver.cpp
QIcon PrometheusIconResolver::icon(const QString &actionId)
{
    const auto it = s_actionMap.constFind(actionId);
    if (it == s_actionMap.constEnd()) {
        qWarning("PrometheusIconResolver: unknown actionId %s", qPrintable(actionId));
        return QIcon();
    }

    // Step 1: bundled resource
    const QIcon bundled(it->first);  // e.g. ":/icons/fa/bolt.svg"
    if (!bundled.isNull()) {
        return bundled;
    }

    // Step 2: QIcon::fromTheme fallback
    if (!it->second.isEmpty()) {
        const QIcon themed = QIcon::fromTheme(it->second, QIcon());
        if (!themed.isNull()) {
            return themed;
        }
    }

    // Step 3: warning + transparent placeholder
    qWarning("PrometheusIconResolver: missing icon for action %s — release gate will fail",
             qPrintable(actionId));
    QPixmap placeholder(1, 1);
    placeholder.fill(Qt::transparent);
    return QIcon(placeholder);
}
```

---

### `falkon/src/lib/agent/prometheusmarkwidget.h/.cpp` (new — component, request-response)

**Analog:** `falkon/src/lib/agent/agentruntimesidebar.cpp` (header block, lines 94-112)

The existing sidebar header uses QLabel + QFont directly to render "Prometheus" and "Powered by FSB". Phase 9 replaces that placeholder with a real `PrometheusMarkWidget` that renders the PM monogram per the logo contract.

**Existing placeholder pattern to replace** (`agentruntimesidebar.cpp` lines 101-112):
```cpp
// Header: PM mark + Prometheus wordmark + Powered by FSB tagline
auto* title = new QLabel(tr("Prometheus"), this);
QFont titleFont = title->font();
titleFont.setPointSize(titleFont.pointSize() + 3);
titleFont.setBold(true);
title->setFont(titleFont);
title->setObjectName(QSL("PrometheusTitle"));
root->addWidget(title);

auto* poweredBy = new QLabel(tr("Powered by FSB"), this);
poweredBy->setObjectName(QSL("PrometheusPoweredBy"));
root->addWidget(poweredBy);
```

**QFont setup reference** — already in agentruntimesidebar.cpp. PrometheusMarkWidget must use:
- Poppins Thin 100 for "P" and Poppins Black 900 for "M" as separate QLabel or QPainter draws
- QFontDatabase to retrieve the registered family (registered at startup via PromethusFontLoader)
- Size rules from 09-UI-SPEC.md: side panel = 12px letter-size inside 26x26 rounded-square

**QWidget subclass pattern** (follow `AgentRuntimeSidebarController` for the controller/widget split, `agentruntimesidebar.h` lines 18-88):
```cpp
class FALKON_EXPORT PrometheusMarkWidget : public QWidget
{
    Q_OBJECT
public:
    enum Size { Compact = 26, Medium = 64, Large = 128 };
    explicit PrometheusMarkWidget(Size size = Compact, QWidget* parent = nullptr);

protected:
    void paintEvent(QPaintEvent* event) override;

private:
    Size m_size;
};
```

---

### `falkon/src/lib/app/mainapplication.cpp` (modified — font registration)

**Analog:** self — existing `QFontDatabase::addApplicationFont` block (lines 150-157)

**Existing Windows-only font registration pattern** (lines 150-158):
```cpp
#ifdef Q_OS_WIN
    // Set default app font (needed for N'ko)
    int fontId = QFontDatabase::addApplicationFont(QSL("font.ttf"));
    if (fontId != -1) {
        const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.empty())
            setFont(QFont(families.at(0)));
    }
#endif
```

**Import already present** (mainapplication.cpp line 58):
```cpp
#include <QFontDatabase>
```

**Pattern to apply — PromethusFontLoader called from loadSettings() or constructor (before any UI):**

The new `PromethusFontLoader::registerAll()` static method must be called in `MainApplication::MainApplication(...)` before `loadSettings()` is called (which is called later via `QTimer::singleShot`). Best insertion point is just after the `QIcon::setThemeName` block at line 140, since font registration must precede any widget construction.

The font loader follows the same `addApplicationFont` / check ID / qWarning pattern but applies to 5 bundled resource paths:
```cpp
// Called once at startup in MainApplication constructor
PromethusFontLoader::registerAll();
```

Where `registerAll()` iterates:
```cpp
static const char* kFontPaths[] = {
    ":/fonts/poppins/Poppins-Thin.ttf",
    ":/fonts/poppins/Poppins-Light.ttf",
    ":/fonts/poppins/Poppins-ExtraBold.ttf",
    ":/fonts/poppins/Poppins-Black.ttf",
    ":/fonts/spacemono/SpaceMono-Regular.ttf",
    nullptr
};
for (int i = 0; kFontPaths[i]; ++i) {
    int id = QFontDatabase::addApplicationFont(QSL(kFontPaths[i]));
    if (id == -1) {
        qWarning("PromethusFontLoader: failed to load %s", kFontPaths[i]);
    }
}
```

---

### `falkon/themes/prometheus/prometheus-dark.qss` (new — config, request-response)

**Analog:** `falkon/themes/linux/main.css`

The linux theme `main.css` is the best analog: it uses QSS selectors with `#objectName` and `qproperty-` custom properties, palette() references, and hardcoded hex colors for the Prometheus accent that already match the dark theme (`#1d1816`, `#ff6b35`, `#ff8c42`).

**Existing structure pattern** (`falkon/themes/linux/main.css` lines 1-143):
```css
/*************************************
 * Linux Theme                       *
 *************************************/

/*MainWindow*/
#mainwindow
{
    background-color: #090909;
}

/*NavigationBar*/
#navigation-button-back
{
    qproperty-themeIcon: "go-previous";
}

#tabbar
{
    qproperty-tabPadding: -1;
    qproperty-baseColor: #141414;
    qproperty-textColor: #f2f2f2;
    qproperty-selectedTextColor: #ff8c42;
}
```

**Dark theme color tokens to use** (from 09-UI-SPEC.md):
```css
/* prometheus-dark.qss — Prometheus warm dark theme */
/* Token reference: see 09-UI-SPEC.md Color — Warm Dark Theme */

/*MainWindow*/
QMainWindow
{
    background-color: #0d0a09; /* --bg-app */
}

QToolBar, #navigationbar
{
    background-color: #1d1816; /* --chrome */
    border-bottom: 1px solid rgba(255,241,232,0.10); /* --border */
}

/*PrometheusAgentSidebar (side panel)*/
#PrometheusAgentSidebar
{
    background-color: #1d1816; /* --chrome */
    color: #f6efe9;            /* --text */
}

/*Tab strip*/
#tabbar
{
    qproperty-baseColor: #141110;        /* --surface */
    qproperty-textColor: #d2c1b4;        /* --text-2 */
    qproperty-selectedTextColor: #ff6b35; /* --accent */
}

/*Location bar*/
#locationbar, #websearchbar
{
    border-color: #ff6b35;                    /* --accent */
    selection-background-color: #ff6b35;
}
```

**Theme switching pattern** from `loadTheme()` (`mainapplication.cpp` lines 1149-1180):
```cpp
void MainApplication::loadTheme(const QString &name)
{
    QString activeThemePath = DataPaths::locate(DataPaths::Themes, name);
    // ...
    QString qss = QzTools::readAllFileContents(activeThemePath + QLatin1String("/main.css"));
    // platform-specific appends...
    setStyleSheet(qss);
}
```

For the prometheus theme the equivalent is: `loadTheme("prometheus")` writes `prometheus-dark.qss` or `prometheus-light.qss` content into `setStyleSheet(qss)`. Theme switching at runtime (no restart) calls `setStyleSheet()` again with the alternate file's content.

---

### `falkon/themes/prometheus/prometheus-light.qss` (new — config, request-response)

**Analog:** Same as `prometheus-dark.qss` — `falkon/themes/linux/main.css`

Light theme uses the same selectors as dark but substitutes the warm light tokens from 09-UI-SPEC.md:

```css
/* prometheus-light.qss — Prometheus warm light theme */

QMainWindow
{
    background-color: #e9e2da; /* --bg-app light */
}

QToolBar, #navigationbar
{
    background-color: #f3ede6; /* --chrome light */
    border-bottom: 1px solid rgba(41,29,20,0.10); /* --border light */
}

#PrometheusAgentSidebar
{
    background-color: #ece4db; /* --chrome-2 light */
    color: #1f1a17;            /* --text light */
}

#tabbar
{
    qproperty-baseColor: #fffdfb;         /* --surface light */
    qproperty-textColor: #6a584d;         /* --text-2 light */
    qproperty-selectedTextColor: #ff6b35; /* --accent (same both themes) */
}
```

Accent values `#ff6b35` / `#ff8c42` are identical in both themes — only surface/text/border tokens differ.

---

### `falkon/themes/prometheus/prometheus-common.qss` (new — config, request-response)

**Analog:** `falkon/themes/mac/main.css` (structurally richer; uses fixed sizing and border-radius rules)

Common QSS holds structural rules that do not vary by theme. Pattern from `mac/main.css` lines 130-155:
```css
ToolButton[toolbar-look="true"]
{
    qproperty-iconSize: 16px 16px;
    qproperty-fixedsize: 36px 23px;
    border-image: url(images/toolbutton.png);
}
```

**Common rules to extract to this file** (from 09-UI-SPEC.md):
```css
/* prometheus-common.qss — shared structure, no color values */

/* Toolbar icon buttons: 30x30 clickable area, 16px icon */
QToolButton[toolbar-look="true"]
{
    qproperty-iconSize: 16px 16px;
    qproperty-fixedsize: 30px 30px;
    border-radius: 8px;  /* --r-sm */
}

/* Side panel mode tab buttons */
#PrometheusAgentSidebar QTabBar::tab
{
    min-height: 30px;
    border-radius: 8px;  /* --r-sm */
    padding: 0px 8px;
}

/* Panel rows */
.pm-row
{
    border-radius: 12px; /* --r-md */
    padding: 9px 8px;    /* spec exception: not 4-multiple */
}

/* Status pill */
.pm-status
{
    border-radius: 9999px; /* --r-pill */
    padding: 0px 8px;
    font-size: 10px;
    font-weight: 600;
}

/* Tab pills */
#tabbar
{
    qproperty-tabPadding: -1;
}

/* Panel width */
#sidebar
{
    min-width: 320px;
    max-width: 320px;
}

/* Disabled state */
*[disabled="true"]
{
    opacity: 0.35;
}
```

---

### `falkon/themes/prometheus/metadata.desktop` (new — config)

**Analog:** `falkon/themes/linux/metadata.desktop`

**Exact pattern** (from `falkon/themes/linux/metadata.desktop`):
```ini
[Desktop Entry]
Name=Linux
Comment=Default Linux theme
X-Falkon-Author=David Rosca
X-Falkon-License=license.txt
Icon=theme.png
```

**New file:**
```ini
[Desktop Entry]
Name=Prometheus
Comment=Warm minimal dark/light theme for Prometheus browser
X-Falkon-Author=FSB
X-Falkon-License=license.txt
Icon=theme.png
```

---

## Shared Patterns

### Icon loading (QIcon from resource path)

**Source:** `falkon/src/lib/app/mainapplication.cpp` line 129 and `agentruntimesidebar.cpp` line 63
**Apply to:** `PrometheusIconResolver`, all callsites replacing `QIcon::fromTheme`

```cpp
// Prefer bundled resource; QIcon::fromTheme as secondary fallback
QIcon::fromTheme(QSL("prometheus"), QIcon(QSL(":icons/prometheus.svg")))
```

The same two-argument `QIcon::fromTheme(name, fallback)` form is the established pattern. `PrometheusIconResolver::icon()` internalizes this so callers never write it inline.

### Theme detection and reload

**Source:** `falkon/src/lib/app/mainapplication.cpp` lines 1149-1180 (`loadTheme`)
**Apply to:** Theme toggle action in settings/tweaks; runtime dark/light switching

```cpp
// loadTheme reads CSS from disk and calls setStyleSheet(qss)
// For runtime switching: call loadTheme("prometheus") again
// The CSS file name encodes dark/light: prometheus-dark.qss vs prometheus-light.qss
// loadTheme selects main.css by convention; prometheus theme adapts this to:
//   prometheus-dark.qss  (for dark mode)
//   prometheus-light.qss (for light mode)
// Both are concatenated with prometheus-common.qss before setStyleSheet
```

### Object naming convention

**Source:** `falkon/src/lib/agent/agentruntimesidebar.cpp` lines 94, 107, 163, 264
**Apply to:** All new phase 9 widgets (PrometheusMarkWidget, status pills, section labels)

```cpp
setObjectName(QSL("PrometheusAgentSidebar"));
title->setObjectName(QSL("PrometheusTitle"));
m_agentStatus->setObjectName(QSL("agentStatusPill"));
pinnedLabel->setObjectName(QSL("sectionLabel"));
```

QSS targets widgets by `#objectName` or `.className[property="value"]`. Phase 9 new widget object names must follow the `Prometheus` prefix convention.

### Property-based styling

**Source:** `falkon/src/lib/agent/agentruntimesidebar.cpp` line 184 and `fsbcontrolpanel.cpp` line 271
**Apply to:** Accent-colored buttons (send, run, primary CTA)

```cpp
m_runTaskBtn->setProperty("accent", true);
// QSS selector: QPushButton[accent="true"] { background: #ff6b35; }
```

Likewise for destructive:
```cpp
m_cancelTaskBtn->setProperty("destructive", true);
// QSS: QPushButton[destructive="true"] { background: #ff5f57; }
```

### CMakeLists source registration

**Source:** `falkon/src/lib/CMakeLists.txt` lines 65-68 (agent block)
**Apply to:** Any new `.cpp` / `.h` files added in phase 9

```cmake
# Under "agent" in the sources list:
agent/agentcommandrouter.cpp
agent/agentruntime.cpp
agent/agentruntimesidebar.cpp
agent/fsbcontrolpanel.cpp
# New phase 9 additions follow the same pattern:
agent/prometheusiconresolver.cpp
agent/prometheusmarkwidget.cpp
```

Headers are listed separately (lines 314-317 pattern):
```cmake
agent/agentcommandrouter.h
agent/agentruntime.h
# ...
agent/prometheusiconresolver.h
agent/prometheusmarkwidget.h
```

---

## Primary `QIcon::fromTheme` Call Sites Needing Bundled Fallbacks

These are the call sites in the primary navigation and sidebar UI where Phase 9 must wire `PrometheusIconResolver::icon()` instead of bare `QIcon::fromTheme()`. Secondary call sites (context menus, preferences) may retain `fromTheme` with a bundled second argument.

| File | Line(s) | Theme Name | Resolver ActionId |
|------|---------|------------|-------------------|
| `navigation/navigationbar.cpp` | 133 | `view-list-icons` | `tab-all` |
| `navigation/navigationbar.cpp` | 143 | `edit-find` | `nav-search` |
| `navigation/locationbar.cpp` | 366, 438 | `edit-find` | `nav-search` |
| `navigation/locationbar.cpp` | 446 | `security-medium` | `nav-lock-secure` |
| `navigation/locationbar.cpp` | 449 | `security-low` | `nav-lock-insecure` |
| `webengine/webview.cpp` | 989 | `edit-undo` | `utility-undo` |
| `webengine/webview.cpp` | 995 | `edit-redo` | `utility-redo` |
| `webengine/webview.cpp` | 1001 | `edit-cut` | `utility-cut` |
| `webengine/webview.cpp` | 1007 | `edit-copy` | `utility-copy` |
| `webengine/webview.cpp` | 1013 | `edit-paste` | `utility-paste` |
| `webengine/webview.cpp` | 1019 | `edit-select-all` | `utility-select-all` |
| `webengine/webview.cpp` | 1023 | `view-refresh` | `nav-reload` |
| `webengine/webview.cpp` | 1027 | `process-stop` | `nav-stop` |
| `agent/agentruntimesidebar.cpp` | 63 | `prometheus` | (keep as-is; PM icon separate from FA) |

The `webview.cpp` edit-action calls (lines 989-1027) are bulk-replaceable: they all follow the same `action->setIcon(QIcon::fromTheme(...))` pattern and map directly to `utility-*` resolver IDs.

---

## No Analog Found

None. All 9 files have a close match in the codebase. Files producing entirely new functionality (`prometheusiconresolver`, `prometheusmarkwidget`) have role-match analogs that provide sufficient structural guidance.

---

## Metadata

**Analog search scope:** `falkon/src/lib/`, `falkon/themes/`, `falkon/src/lib/data/`
**Files scanned:** 18
**Pattern extraction date:** 2026-06-17
