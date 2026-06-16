# Phase 07: Compact Safari-style Browser Chrome and Advanced Tab Management - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 19 likely new/modified files or component areas
**Analogs found:** 19 / 19

## File Classification

| New/Modified File or Area | Role | Data Flow | Closest Analog | Match Quality |
|---------------------------|------|-----------|----------------|---------------|
| `falkon/src/lib/preferences/preferences.cpp` | config/controller | settings file I/O | `falkon/src/lib/preferences/preferences.cpp` | exact |
| `falkon/src/lib/preferences/preferences.ui` | config/component | settings file I/O | `falkon/src/lib/preferences/preferences.ui` | exact |
| `falkon/src/lib/other/qzsettings.{h,cpp}` | config/cache | settings file I/O | `falkon/src/lib/other/qzsettings.cpp` | exact |
| `falkon/src/lib/app/browserwindow.{h,cpp}` | controller | event-driven, request-response | `falkon/src/lib/app/browserwindow.cpp` | exact |
| `falkon/src/lib/navigation/navigationbar.{h,cpp}` | component | event-driven layout | `falkon/src/lib/navigation/navigationbar.cpp` | exact |
| `falkon/src/lib/navigation/locationbar.{h,cpp}` | component | request-response, transform | `falkon/src/lib/navigation/locationbar.cpp` | exact |
| `falkon/src/lib/tabwidget/tabwidget.{h,cpp}` | component/controller | CRUD, event-driven | `falkon/src/lib/tabwidget/tabwidget.cpp` | exact |
| `falkon/src/lib/tabwidget/tabbar.{h,cpp}` | component | event-driven, drag/drop | `falkon/src/lib/tabwidget/tabbar.cpp` | exact |
| `falkon/src/lib/tabwidget/combotabbar.{h,cpp}` | component | event-driven, overflow layout | `falkon/src/lib/tabwidget/combotabbar.cpp` | exact |
| `falkon/src/lib/tabwidget/compacttabstrip.{h,cpp}` or equivalent new compact tab widget | component | event-driven, drag/drop | `falkon/src/lib/tabwidget/tabbar.cpp` + `falkon/src/plugins/VerticalTabs/tablistdelegate.cpp` | role-match |
| `falkon/src/lib/tabwidget/tabmodel.{h,cpp}` | model | CRUD, drag/drop, transform | `falkon/src/lib/tabwidget/tabmodel.{h,cpp}` | exact |
| `falkon/src/lib/tabwidget/tabmrumodel.{h,cpp}` | model/proxy | event-driven ordering | `falkon/src/lib/tabwidget/tabmrumodel.cpp` | exact |
| `falkon/src/lib/tabwidget/tabgroupmodel.{h,cpp}` or tab group metadata extension | model | CRUD, event-driven | `falkon/src/lib/tabwidget/tabtreemodel.cpp` + `falkon/src/plugins/VerticalTabs/verticaltabswidget.cpp` | role-match |
| `falkon/src/lib/tabwidget/taboverviewpopup.{h,cpp}` or `tabsearchpopup.{h,cpp}` | component | request-response, event-driven search/filter | `falkon/src/plugins/TabManager/tabmanagerwidget.cpp` + `falkon/src/plugins/VerticalTabs/tablistview.cpp` | role-match |
| `falkon/src/lib/tabwidget/tabcontextmenu.{h,cpp}` | component/controller | request-response actions | `falkon/src/lib/tabwidget/tabcontextmenu.cpp` | exact |
| `falkon/src/lib/agent/agentcommandrouter.{h,cpp}` or read-only tab state provider | service | request-response, in-memory state | `falkon/src/lib/agent/agentcommandrouter.{h,cpp}` | exact |
| `falkon/src/lib/CMakeLists.txt` | config/build | build graph | `falkon/src/lib/CMakeLists.txt` | exact |
| `falkon/autotests/tabmodeltest.cpp` | test | model events, CRUD | `falkon/autotests/tabmodeltest.cpp` | exact |
| `falkon/autotests/locationbartest.cpp` | test | parser transform | `falkon/autotests/locationbartest.cpp` | exact |

## Pattern Assignments

### `falkon/src/lib/preferences/preferences.cpp` (config/controller, settings file I/O)

**Analog:** `falkon/src/lib/preferences/preferences.cpp`

**Load tab settings pattern** (lines 252-266):
```cpp
settings.beginGroup(QSL("Browser-Tabs-Settings"));
ui->hideTabsOnTab->setChecked(settings.value(QSL("hideTabsWithOneTab"), false).toBool());
ui->activateLastTab->setChecked(settings.value(QSL("ActivateLastTabWhenClosingActual"), false).toBool());
ui->openNewTabAfterActive->setChecked(settings.value(QSL("newTabAfterActive"), true).toBool());
ui->openNewEmptyTabAfterActive->setChecked(settings.value(QSL("newEmptyTabAfterActive"), false).toBool());
ui->openPopupsInTabs->setChecked(settings.value(QSL("OpenPopupsInTabs"), false).toBool());
ui->blockAutomaticPopups->setChecked(settings.value(QSL("BlockAutomaticPopups"), false).toBool());
ui->alwaysSwitchTabsWithWheel->setChecked(settings.value(QSL("AlwaysSwitchTabsWithWheel"), false).toBool());
ui->switchToNewTabs->setChecked(settings.value(QSL("OpenNewTabsSelected"), false).toBool());
ui->dontCloseOnLastTab->setChecked(settings.value(QSL("dontCloseWithOneTab"), false).toBool());
ui->askWhenClosingMultipleTabs->setChecked(settings.value(QSL("AskOnClosing"), false).toBool());
ui->showClosedTabsButton->setChecked(settings.value(QSL("showClosedTabsButton"), false).toBool());
ui->showCloseOnInactive->setCurrentIndex(settings.value(QSL("showCloseOnInactiveTabs"), 0).toInt());
settings.endGroup();
```

**Save tab settings pattern** (lines 989-1003):
```cpp
settings.beginGroup(QSL("Browser-Tabs-Settings"));
settings.setValue(QSL("hideTabsWithOneTab"), ui->hideTabsOnTab->isChecked());
settings.setValue(QSL("ActivateLastTabWhenClosingActual"), ui->activateLastTab->isChecked());
settings.setValue(QSL("newTabAfterActive"), ui->openNewTabAfterActive->isChecked());
settings.setValue(QSL("newEmptyTabAfterActive"), ui->openNewEmptyTabAfterActive->isChecked());
settings.setValue(QSL("OpenPopupsInTabs"), ui->openPopupsInTabs->isChecked());
settings.setValue(QSL("BlockAutomaticPopups"), ui->blockAutomaticPopups->isChecked());
settings.setValue(QSL("AlwaysSwitchTabsWithWheel"), ui->alwaysSwitchTabsWithWheel->isChecked());
settings.setValue(QSL("OpenNewTabsSelected"), ui->switchToNewTabs->isChecked());
settings.setValue(QSL("dontCloseWithOneTab"), ui->dontCloseOnLastTab->isChecked());
settings.setValue(QSL("AskOnClosing"), ui->askWhenClosingMultipleTabs->isChecked());
settings.setValue(QSL("showClosedTabsButton"), ui->showClosedTabsButton->isChecked());
settings.setValue(QSL("showCloseOnInactiveTabs"), ui->showCloseOnInactive->currentIndex());
settings.endGroup();
```

**Reload propagation pattern** (lines 1173-1176):
```cpp
mApp->cookieJar()->loadSettings();
mApp->siteSettingsManager()->loadSettings();
mApp->history()->loadSettings();
mApp->reloadSettings();
```

Apply for `tabLayout` and `tabDisplay`: read and write in the same `Browser-Tabs-Settings` group; after Preferences save, rely on existing `mApp->reloadSettings()`.

---

### `falkon/src/lib/preferences/preferences.ui` (config/component, settings UI)

**Analog:** `falkon/src/lib/preferences/preferences.ui`

**Tabs page insertion point** (lines 714-718):
```xml
<widget class="QWidget" name="tabsBehaviourPage">
 <attribute name="title">
  <string>Tabs behaviour</string>
 </attribute>
 <layout class="QVBoxLayout" name="verticalLayout_2">
```

**Existing combo-row pattern** (lines 797-823):
```xml
<layout class="QHBoxLayout" name="horizontalLayout_21">
 <item>
  <widget class="QLabel" name="label_65">
   <property name="text">
    <string>Show close buttons on inactive tabs:</string>
   </property>
  </widget>
 </item>
 <item>
  <widget class="QComboBox" name="showCloseOnInactive">
   <item>
    <property name="text">
     <string>Automatic</string>
    </property>
   </item>
```

Apply for:
- `Tab Layout`: `Compact`, `Separate`
- `Tab Display`: `Title and Icon`, `Favicon Only`

Use the same `QHBoxLayout` + `QLabel` + `QComboBox` structure under `tabsBehaviourPage`. Keep copy exactly aligned with `07-UI-SPEC.md`.

---

### `falkon/src/lib/other/qzsettings.{h,cpp}` (config/cache, settings file I/O)

**Analog:** `falkon/src/lib/other/qzsettings.{h,cpp}`

**Header field pattern** (lines 63-69):
```cpp
// Browser-Tabs-Settings
Qz::NewTabPositionFlags newTabPosition;
bool tabsOnTop;
bool openPopupsInTabs;
bool blockAutomaticPopups;
bool alwaysSwitchTabsWithWheel;
```

**Load pattern** (lines 62-68):
```cpp
settings.beginGroup(QSL("Browser-Tabs-Settings"));
newTabPosition = settings.value(QSL("OpenNewTabsSelected"), false).toBool() ? Qz::NT_CleanSelectedTab : Qz::NT_CleanNotSelectedTab;
tabsOnTop = settings.value(QSL("TabsOnTop"), true).toBool();
openPopupsInTabs = settings.value(QSL("OpenPopupsInTabs"), false).toBool();
blockAutomaticPopups = settings.value(QSL("BlockAutomaticPopups"), false).toBool();
alwaysSwitchTabsWithWheel = settings.value(QSL("AlwaysSwitchTabsWithWheel"), false).toBool();
settings.endGroup();
```

**Save pattern** (lines 86-88):
```cpp
settings.beginGroup(QSL("Browser-Tabs-Settings"));
settings.setValue(QSL("TabsOnTop"), tabsOnTop);
settings.endGroup();
```

Use this only for runtime-wide reads if needed by multiple chrome widgets. If only `TabWidget`/`TabBar` need the values, local `loadSettings()` reads are enough.

---

### `falkon/src/lib/app/browserwindow.{h,cpp}` (controller, event-driven/request-response)

**Analog:** `falkon/src/lib/app/browserwindow.{h,cpp}`

**Accessor pattern** (header lines 112-126):
```cpp
LocationBar* locationBar() const;
TabWidget* tabWidget() const;
NavigationBar* navigationBar() const;
QAction* action(const QString &name) const;
TabModel *tabModel() const;
TabMruModel *tabMruModel() const;
```

**Composition pattern** (lines 372-379):
```cpp
m_tabWidget = new TabWidget(this);
m_superMenu = new QMenu(this);
m_navigationToolbar = new NavigationBar(this);
m_bookmarksToolbar = new BookmarksToolbar(this);

m_tabModel = new TabModel(this, this);
m_tabMruModel = new TabMruModel(this, this);
m_tabMruModel->setSourceModel(m_tabModel);
```

**Shortcut pattern** (lines 473-482):
```cpp
auto* closeTabAction = new QShortcut(QKeySequence(QSL("Ctrl+W")), this);
auto* closeTabAction2 = new QShortcut(QKeySequence(QSL("Ctrl+F4")), this);
connect(closeTabAction, &QShortcut::activated, this, &BrowserWindow::closeTab);
connect(closeTabAction2, &QShortcut::activated, this, &BrowserWindow::closeTab);

auto* reloadAction = new QShortcut(QKeySequence(QSL("Ctrl+R")), this);
connect(reloadAction, &QShortcut::activated, this, &BrowserWindow::reload);

auto* openLocationAction = new QShortcut(QKeySequence(QSL("Alt+D")), this);
connect(openLocationAction, &QShortcut::activated, this, &BrowserWindow::openLocation);
```

**Open location focus pattern** (lines 1186-1193):
```cpp
void BrowserWindow::openLocation()
{
    if (isFullScreen()) {
        showNavigationWithFullScreen();
    }

    locationBar()->setFocus();
    locationBar()->selectAll();
}
```

Apply for compact mode:
- Keep `Ctrl+L`, `Alt+D`, and `Qt::Key_OpenUrl` routed to `BrowserWindow::openLocation()`.
- If compact mode wraps the active tab/address field, `BrowserWindow::locationBar()` must still resolve the current tab's existing `LocationBar`.

---

### `falkon/src/lib/navigation/navigationbar.{h,cpp}` (component, event-driven layout)

**Analog:** `falkon/src/lib/navigation/navigationbar.cpp`

**Existing active location stack embedding** (lines 155-162):
```cpp
m_searchLine = new WebSearchBar(m_window);

m_navigationSplitter = new QSplitter(this);
m_navigationSplitter->addWidget(m_window->tabWidget()->locationBars());
m_navigationSplitter->addWidget(m_searchLine);

m_navigationSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Maximum);
m_navigationSplitter->setCollapsible(0, false);
```

**Toolbar widget registration pattern** (lines 192-198):
```cpp
addWidget(backNextWidget, QSL("button-backforward"), tr("Back and Forward buttons"));
addWidget(m_reloadStop, QSL("button-reloadstop"), tr("Reload button"));
addWidget(buttonHome, QSL("button-home"), tr("Home button"));
addWidget(buttonAddTab, QSL("button-addtab"), tr("Add tab button"));
addWidget(m_navigationSplitter, QSL("locationbar"), tr("Address and Search bar"));
addWidget(buttonTools, QSL("button-tools"), tr("Tools button"));
addWidget(m_exitFullscreen, QSL("button-exitfullscreen"), tr("Exit Fullscreen button"));
```

**Settings-driven layout pattern** (lines 530-555):
```cpp
void NavigationBar::loadSettings()
{
    const QStringList defaultIds = {
        QSL("button-backforward"),
        QSL("button-reloadstop"),
        QSL("button-home"),
        QSL("locationbar"),
        QSL("button-downloads"),
        QSL("adblock-icon"),
        QSL("button-tools")
    };

    Settings settings;
    settings.beginGroup(QSL("NavigationBar"));
    m_layoutIds = settings.value(QSL("Layout"), defaultIds).toStringList();
    m_searchLine->setVisible(settings.value(QSL("ShowSearchBar"), true).toBool());
    settings.endGroup();

    m_layoutIds.removeDuplicates();
    m_layoutIds.removeAll(QString());
    if (!m_layoutIds.contains(QSL("locationbar"))) {
        m_layoutIds.append(QSL("locationbar"));
    }

    reloadLayout();
}
```

**Layout reload pattern** (lines 563-595):
```cpp
setUpdatesEnabled(false);

while (m_layout->count() != 0) {
    QLayoutItem *item = m_layout->takeAt(0);
    if (!item) {
        continue;
    }
    QWidget *widget = item->widget();
    if (!widget) {
        continue;
    }
    widget->setParent(nullptr);
}

for (const WidgetData &data : m_widgets) {
    data.widget->hide();
}

for (const QString &id : std::as_const(m_layoutIds)) {
    const WidgetData data = m_widgets.value(id);
    if (data.widget) {
        m_layout->addWidget(data.widget);
        auto *button = qobject_cast<NavigationBarToolButton*>(data.widget);
        if (button) {
            button->updateVisibility();
        } else {
            data.widget->show();
        }
    }
}
```

Apply for compact mode:
- Add compact tab strip/address cluster through `addWidget()` or a directly managed child with the same hide/reparent/reload discipline.
- Do not duplicate the `LocationBar`; reuse `m_window->tabWidget()->locationBars()`.
- Load `tabLayout` and choose compact/separate composition in a setting reload path.

---

### `falkon/src/lib/navigation/locationbar.{h,cpp}` (component, request-response/transform)

**Analog:** `falkon/src/lib/navigation/locationbar.{h,cpp}`

**Public API to reuse** (header lines 66-73):
```cpp
static QString convertUrlToText(const QUrl &url);
static SearchEngine searchEngine();
static LoadAction loadAction(const QString &text);

public Q_SLOTS:
    void setText(const QString &text);
    void showUrl(const QUrl &url);
    void loadRequest(const LoadRequest &request);
```

**Completion and settings connection pattern** (lines 80-107):
```cpp
connect(m_completer, &LocationCompleter::showDomainCompletion, this, &LocationBar::showDomainCompletion);
connect(m_completer, &LocationCompleter::clearCompletion, this, &LocationBar::clearCompletion);
connect(m_completer, &LocationCompleter::loadRequested, this, &LocationBar::loadRequest);
connect(m_completer, &LocationCompleter::popupClosed, this, &LocationBar::updateSiteIcon);
...
connect(mApp, &MainApplication::settingsReloaded, this, &LocationBar::loadSettings);

loadSettings();
```

**Edit-to-search pattern** (lines 353-372):
```cpp
void LocationBar::requestLoadUrl()
{
    loadRequest(loadAction(text()).loadRequest);
    updateSiteIcon();
}

void LocationBar::textEdited(const QString &text)
{
    m_oldTextLength = m_currentTextLength;
    m_currentTextLength = text.length();

    if (!text.isEmpty()) {
        m_completer->complete(text);
        m_siteIcon->setIcon(QIcon::fromTheme(QSL("edit-find"), QIcon(QSL(":icons/menu/search-icon.svg"))));
    }
    else {
        m_completer->closePopup();
    }

    setGoIconVisible(true);
}
```

**Load progress paint hook** (lines 650-687):
```cpp
void LocationBar::loadStarted()
{
    m_progressVisible = true;
    m_progressTimer->stop();
    m_autofillIcon->hide();
}

void LocationBar::loadProgress(int progress)
{
    if (qzSettings->showLoadingProgress) {
        m_loadProgress = progress;
        update();
    }
}

void LocationBar::loadSettings()
{
    Settings settings;
    settings.beginGroup(QSL("AddressBar"));
    m_progressStyle = static_cast<ProgressStyle>(settings.value(QSL("ProgressStyle"), 0).toInt());
    bool customColor = settings.value(QSL("UseCustomProgressColor"), false).toBool();
    m_progressColor = customColor ? settings.value(QSL("CustomProgressColor"), palette().color(QPalette::Highlight)).value<QColor>() : QColor();
    settings.endGroup();
}
```

Apply for compact active tab/address:
- Wrap or restyle the current `LocationBar`; do not reimplement `loadAction()`, completion, site icon, or progress.
- Preserve existing security/privacy icon behavior and avoid using FSB orange for secure-origin cues.

---

### `falkon/src/lib/tabwidget/tabwidget.{h,cpp}` (component/controller, CRUD/event-driven)

**Analog:** `falkon/src/lib/tabwidget/tabwidget.{h,cpp}`

**Public operations pattern** (header lines 88-129):
```cpp
TabBar* tabBar() const;
ClosedTabsManager* closedTabsManager() const;
QList<WebTab*> allTabs(bool withPinned = true);
bool canRestoreTab() const;
QStackedWidget* locationBars() const;
ToolButton* buttonClosedTabs() const;
AddTabButton* buttonAddTab() const;
...
int duplicateTab(int index);
void requestCloseTab(int index = -1);
void closeAllButCurrent(int index);
void closeToRight(int index);
void closeToLeft(int index);
void detachTab(int index);
void loadTab(int index);
void unloadTab(int index);
void restoreClosedTab(QObject* obj = nullptr);
```

**Constructor wiring pattern** (lines 96-149):
```cpp
connect(m_tabBar, &ComboTabBar::tabCloseRequested, this, &TabWidget::requestCloseTab);
connect(m_tabBar, &TabBar::tabMoved, this, &TabWidget::tabWasMoved);
connect(m_tabBar, &TabBar::moveAddTabButton, this, &TabWidget::moveAddTabButton);
connect(mApp, &MainApplication::settingsReloaded, this, &TabWidget::loadSettings);

m_menuTabs = new MenuTabs(this);
connect(m_menuTabs, &MenuTabs::closeTab, this, &TabWidget::requestCloseTab);
...
connect(m_buttonListTabs, &ToolButton::aboutToShowMenu, this, &TabWidget::aboutToShowTabsMenu);
...
connect(m_tabBar, &ComboTabBar::overFlowChanged, this, &TabWidget::tabBarOverFlowChanged);

loadSettings();
```

**Tab settings pattern** (lines 157-173):
```cpp
Settings settings;
settings.beginGroup(QSL("Browser-Tabs-Settings"));
m_dontCloseWithOneTab = settings.value(QSL("dontCloseWithOneTab"), false).toBool();
m_showClosedTabsButton = settings.value(QSL("showClosedTabsButton"), false).toBool();
m_newTabAfterActive = settings.value(QSL("newTabAfterActive"), true).toBool();
m_newEmptyTabAfterActive = settings.value(QSL("newEmptyTabAfterActive"), false).toBool();
settings.endGroup();

settings.beginGroup(QSL("Web-URL-Settings"));
m_urlOnNewTab = settings.value(QSL("newTabUrl"), QSL("falkon:speeddial")).toUrl();
settings.endGroup();

m_tabBar->loadSettings();

updateClosedTabsButton();
```

**LocationBar stack pattern** (lines 345-349 and 514-518):
```cpp
auto* webTab = new WebTab(m_window);
webTab->setPinned(pinned);
webTab->locationBar()->showUrl(url);
m_locationBars->addWidget(webTab->locationBar());
```

```cpp
LocationBar* locBar = webTab->locationBar();

if (locBar && m_locationBars->indexOf(locBar) != -1) {
    m_locationBars->setCurrentWidget(locBar);
}
```

**Closed tabs menu pattern** (lines 282-300):
```cpp
m_menuClosedTabs->clear();

const auto closedTabs = closedTabsManager()->closedTabs();
for (int i = 0; i < closedTabs.count(); ++i) {
    const ClosedTabsManager::Tab tab = closedTabs.at(i);
    const QString title = QzTools::truncatedText(tab.tabState.title, 40);
    m_menuClosedTabs->addAction(tab.tabState.icon, title, this, SLOT(restoreClosedTab()))->setData(i);
}

if (m_menuClosedTabs->isEmpty()) {
    m_menuClosedTabs->addAction(tr("Empty"))->setEnabled(false);
}
else {
    m_menuClosedTabs->addSeparator();
    m_menuClosedTabs->addAction(tr("Restore All Closed Tabs"), this, &TabWidget::restoreAllClosedTabs);
    m_menuClosedTabs->addAction(QIcon::fromTheme(QSL("edit-clear")), tr("Clear list"), this, &TabWidget::clearClosedTabsList);
}
```

Apply for advanced actions:
- Overview/search row actions should call these existing `TabWidget` methods.
- Compact/separate switching should reuse `m_locationBars` and existing `TabBar` state, not create independent tab operation code.

---

### `falkon/src/lib/tabwidget/tabbar.{h,cpp}` (component, event-driven/drag-drop)

**Analog:** `falkon/src/lib/tabwidget/tabbar.{h,cpp}`

**Widget setup pattern** (lines 96-114):
```cpp
setObjectName(QSL("tabbar"));
setElideMode(Qt::ElideRight);
setFocusPolicy(Qt::NoFocus);
setTabsClosable(false);
setMouseTracking(true);
setDocumentMode(true);
setAcceptDrops(true);
setDrawBase(false);
setMovable(true);

connect(this, &ComboTabBar::currentChanged, this, &TabBar::currentTabChanged);

setUsesScrollButtons(true);
setCloseButtonsToolTip(BrowserWindow::tr("Close Tab"));
connect(this, &ComboTabBar::overFlowChanged, this, &TabBar::overflowChanged);
```

**Settings pattern** (lines 126-139):
```cpp
Settings settings;
settings.beginGroup(QSL("Browser-Tabs-Settings"));
m_hideTabBarWithOneTab = settings.value(QSL("hideTabsWithOneTab"), false).toBool();
bool activateLastTab = settings.value(QSL("ActivateLastTabWhenClosingActual"), false).toBool();
m_showCloseOnInactive = settings.value(QSL("showCloseOnInactiveTabs"), 0).toInt(nullptr);
settings.endGroup();

setSelectionBehaviorOnRemove(activateLastTab ? QTabBar::SelectPreviousTab : QTabBar::SelectRightTab);
setVisible(!(count() <= 1 && m_hideTabBarWithOneTab));

setUpLayout();
```

**CSS/custom metrics pattern** (lines 44-85):
```cpp
class TabBarTabMetrics : public QWidget
{
    Q_OBJECT
    Q_PROPERTY(int normalMaxWidth READ normalMaxWidth WRITE setNormalMaxWidth)
    Q_PROPERTY(int normalMinWidth READ normalMinWidth WRITE setNormalMinWidth)
    Q_PROPERTY(int activeMinWidth READ activeMinWidth WRITE setActiveMinWidth)
    Q_PROPERTY(int overflowedWidth READ overflowedWidth WRITE setOverflowedWidth)
    Q_PROPERTY(int pinnedWidth READ pinnedWidth WRITE setPinnedWidth)
...
Q_GLOBAL_STATIC(TabBarTabMetrics, tabMetrics)
```

**Width calculation pattern** (lines 203-251):
```cpp
int availableWidth = mainTabBarWidth() - comboTabBarPixelMetric(ExtraReservedWidth);
...
const int normalTabsCount = ComboTabBar::normalTabsCount();
const int maxTabWidth = comboTabBarPixelMetric(ComboTabBar::NormalTabMaximumWidth);

if (availableWidth >= maxTabWidth * normalTabsCount) {
    m_normalTabWidth = maxTabWidth;
    size.setWidth(m_normalTabWidth);
}
else if (normalTabsCount > 0) {
    const int minActiveTabWidth = comboTabBarPixelMetric(ComboTabBar::ActiveTabMinimumWidth);

    int maxWidthForTab = availableWidth / normalTabsCount;
    int realTabWidth = maxWidthForTab;
    bool adjustingActiveTab = false;

    if (realTabWidth < minActiveTabWidth) {
        maxWidthForTab = normalTabsCount > 1 ? (availableWidth - minActiveTabWidth) / (normalTabsCount - 1) : 0;
        realTabWidth = minActiveTabWidth;
        adjustingActiveTab = true;
    }
```

**Pixel metric pattern** (lines 291-317):
```cpp
switch (sizeType) {
case ComboTabBar::PinnedTabWidth:
    return tabMetrics()->pinnedWidth() > 0 ? tabMetrics()->pinnedWidth() : 32;
case ComboTabBar::ActiveTabMinimumWidth:
    return tabMetrics()->activeMinWidth();
case ComboTabBar::NormalTabMinimumWidth:
    return tabMetrics()->normalMinWidth();
case ComboTabBar::OverflowedTabWidth:
    return tabMetrics()->overflowedWidth();
case ComboTabBar::NormalTabMaximumWidth:
    return tabMetrics()->normalMaxWidth();
case ComboTabBar::ExtraReservedWidth:
    return m_tabWidget->extraReservedWidth();
default:
    break;
}
```

Apply for compact strip:
- Implement compact widths from `07-UI-SPEC.md` through the same metric path: active min 180/preferred 320/max 520, inactive min 72/preferred 144/max 176, pinned 32.
- Preserve elision (`Qt::ElideRight`) and existing drag/drop/context menu behavior.

---

### `falkon/src/lib/tabwidget/combotabbar.{h,cpp}` (component, overflow layout/drag-drop)

**Analog:** `falkon/src/lib/tabwidget/combotabbar.cpp`

**Pinned/main tab routing pattern** (lines 174-182):
```cpp
void ComboTabBar::moveTab(int from, int to)
{
    if (from >= pinnedTabsCount() && to >= pinnedTabsCount()) {
        m_mainTabBar->moveTab(from - pinnedTabsCount(), to - pinnedTabsCount());
    }
    else if (from < pinnedTabsCount() && to < pinnedTabsCount()) {
        m_pinnedTabBar->moveTab(from, to);
    }
}
```

**Tab hit-test pattern** (lines 223-235):
```cpp
int ComboTabBar::tabAt(const QPoint &pos) const
{
    QWidget* w = QApplication::widgetAt(mapToGlobal(pos));
    if (!qobject_cast<TabBarHelper*>(w) && !qobject_cast<TabIcon*>(w) && !qobject_cast<CloseButton*>(w))
        return -1;

    if (m_pinnedTabBarWidget->geometry().contains(pos)) {
        return m_pinnedTabBarWidget->tabAt(m_pinnedTabBarWidget->mapFromParent(pos));
    } else if (m_mainTabBarWidget->geometry().contains(pos)) {
        int index = m_mainTabBarWidget->tabAt(m_mainTabBarWidget->mapFromParent(pos));
        if (index != -1)
            index += pinnedTabsCount();
        return index;
```

**Default metric pattern** (lines 727-748):
```cpp
switch (sizeType) {
case ExtraReservedWidth:
    return 0;
case NormalTabMaximumWidth:
    return 150;
case ActiveTabMinimumWidth:
case NormalTabMinimumWidth:
case OverflowedTabWidth:
    return 100;
case PinnedTabWidth:
    return 30;
default:
    break;
}

return -1;
```

**Tab pixmap/elision pattern** (lines 1087-1099):
```cpp
if (closeButton) {
    const int width = tab.fontMetrics.horizontalAdvance(tab.text) + closeButton->width();
    tab.text = tab.fontMetrics.elidedText(tabText(index), Qt::ElideRight, width);
}

QPixmap out(tab.rect.size() * devicePixelRatioF());
out.setDevicePixelRatio(devicePixelRatioF());
out.fill(Qt::transparent);
tab.rect = QRect(QPoint(0, 0), tab.rect.size());

QPainter p(&out);
style()->drawControl(QStyle::CE_TabBarTab, &tab, &p, this);
```

Apply for compact overflow:
- Reuse `ComboTabBar` mechanics where possible. If compact strip is separate, copy the pinned/main routing and overflow metrics instead of rewriting tab movement rules.

---

### `falkon/src/lib/tabwidget/compacttabstrip.{h,cpp}` or equivalent new compact tab widget (component, event-driven)

**Analogs:** `falkon/src/lib/tabwidget/tabbar.cpp`, `falkon/src/plugins/VerticalTabs/tablistdelegate.cpp`, `falkon/src/plugins/VerticalTabs/tablistview.cpp`

**Base from `TabBar` setup** (lines 96-114):
```cpp
setElideMode(Qt::ElideRight);
setFocusPolicy(Qt::NoFocus);
setMouseTracking(true);
setDocumentMode(true);
setAcceptDrops(true);
setMovable(true);
connect(this, &ComboTabBar::currentChanged, this, &TabBar::currentTabChanged);
setUsesScrollButtons(true);
```

**Dense row icon/state drawing from `TabListDelegate`** (lines 85-113):
```cpp
const int iconSize = 16;
const int iconYPos = center - (iconSize / 2);
QRect iconRect(leftPosition, iconYPos, iconSize, iconSize);
QPixmap pixmap;
if (index.data(TabModel::LoadingRole).toBool()) {
    pixmap = m_loadingAnimator->pixmap(index);
} else {
    pixmap = index.data(Qt::DecorationRole).value<QIcon>().pixmap(iconSize);
}
painter->drawPixmap(iconRect, pixmap);
...
QString title = opt.fontMetrics.elidedText(index.data().toString(), Qt::ElideRight, titleRect.width());
style->drawItemText(painter, titleRect, Qt::AlignLeft, textPalette, true, title, colorRole);
```

**Native interactions from `TabListView`** (lines 148-216):
```cpp
const QModelIndex index = indexAt(me->pos());
auto *tab = index.data(TabModel::WebTabRole).value<WebTab*>();
if (me->buttons() == Qt::MiddleButton && tab) {
    tab->closeTab();
}
...
if (m_pressedButton == NoButton && tab) {
    tab->makeCurrentTab();
}
...
TabContextMenu::Options options = TabContextMenu::HorizontalTabs | TabContextMenu::ShowDetachTabAction;
TabContextMenu menu(tabIndex, m_window, options);
menu.exec(ce->globalPos());
```

Apply:
- For title-and-icon vs favicon-only, keep row height fixed and switch only text visibility/width policy.
- Agent/supervision badges should be extra right-edge paint elements, like audio icons, and should not displace native icon/title more than needed.

---

### `falkon/src/lib/tabwidget/tabmodel.{h,cpp}` (model, CRUD/drag-drop/transform)

**Analog:** `falkon/src/lib/tabwidget/tabmodel.{h,cpp}`

**Role enum pattern** (header lines 53-64):
```cpp
enum Roles {
    WebTabRole = Qt::UserRole + 1,
    TitleRole = Qt::UserRole + 2,
    IconRole = Qt::UserRole + 3,
    PinnedRole = Qt::UserRole + 4,
    RestoredRole = Qt::UserRole + 5,
    CurrentTabRole = Qt::UserRole + 6,
    LoadingRole = Qt::UserRole + 7,
    AudioPlayingRole = Qt::UserRole + 8,
    AudioMutedRole = Qt::UserRole + 9,
    BackgroundActivityRole = Qt::UserRole + 10
};
```

**Data role pattern** (lines 104-138):
```cpp
switch (role) {
case WebTabRole:
    return QVariant::fromValue(t);
case TitleRole:
case Qt::DisplayRole:
    return t->title();
case IconRole:
case Qt::DecorationRole:
    return t->icon();
case PinnedRole:
    return t->isPinned();
case RestoredRole:
    return t->isRestored();
case CurrentTabRole:
    return t->isCurrentTab();
case LoadingRole:
    return t->isLoading();
case AudioPlayingRole:
    return t->isPlaying();
case AudioMutedRole:
    return t->isMuted();
case BackgroundActivityRole:
    return t->backgroundActivity();
default:
    return {};
}
```

**Drag/drop move pattern** (lines 152-204):
```cpp
auto *tab = indexes.at(0).data(WebTabRole).value<WebTab*>();
if (!tab) {
    return nullptr;
}
auto *mimeData = new TabModelMimeData;
mimeData->setTab(tab);
return mimeData;
...
if (tab->browserWindow() == m_window) {
    if (row < 0) {
        row = tab->isPinned() ? m_window->tabWidget()->pinnedTabsCount() : m_window->tabWidget()->count();
    }
    tab->moveTab(row > mimeData->tab()->tabIndex() ? row - 1 : row);
} else {
    if (row < 0) {
        row = m_window->tabCount();
    }
    if (tab->browserWindow()) {
        tab->browserWindow()->tabWidget()->detachTab(tab);
    }
    tab->setPinned(row < m_window->tabWidget()->pinnedTabsCount());
    m_window->tabWidget()->insertView(row, tab, Qz::NT_SelectedTab);
}
```

**Signal-to-role update pattern** (lines 233-248):
```cpp
auto emitDataChanged = [this](WebTab *tab, int role) {
    const QModelIndex idx = tabIndex(tab);
    Q_EMIT dataChanged(idx, idx, {role});
};

connect(tab, &WebTab::titleChanged, this, std::bind(emitDataChanged, tab, Qt::DisplayRole));
connect(tab, &WebTab::titleChanged, this, std::bind(emitDataChanged, tab, TitleRole));
connect(tab, &WebTab::iconChanged, this, std::bind(emitDataChanged, tab, Qt::DecorationRole));
connect(tab, &WebTab::iconChanged, this, std::bind(emitDataChanged, tab, IconRole));
connect(tab, &WebTab::pinnedChanged, this, std::bind(emitDataChanged, tab, PinnedRole));
connect(tab, &WebTab::restoredChanged, this, std::bind(emitDataChanged, tab, RestoredRole));
connect(tab, &WebTab::currentTabChanged, this, std::bind(emitDataChanged, tab, CurrentTabRole));
connect(tab, &WebTab::loadingChanged, this, std::bind(emitDataChanged, tab, LoadingRole));
connect(tab, &WebTab::playingChanged, this, std::bind(emitDataChanged, tab, AudioPlayingRole));
connect(tab, &WebTab::mutedChanged, this, std::bind(emitDataChanged, tab, AudioMutedRole));
connect(tab, &WebTab::backgroundActivityChanged, this, std::bind(emitDataChanged, tab, BackgroundActivityRole));
```

Apply:
- Add group/owner/supervision/health roles here if multiple UI surfaces need them.
- Back roles with `WebTab` signals or a provider signal so overview/search/compact strip refresh through `dataChanged`, not ad-hoc polling.

---

### `falkon/src/lib/tabwidget/tabmrumodel.{h,cpp}` (model/proxy, event-driven ordering)

**Analog:** `falkon/src/lib/tabwidget/tabmrumodel.cpp`

**Proxy setup pattern** (lines 46-51):
```cpp
TabMruModel::TabMruModel(BrowserWindow *window, QObject *parent)
    : QAbstractProxyModel(parent)
    , m_window(window)
{
    connect(this, &QAbstractProxyModel::sourceModelChanged, this, &TabMruModel::init);
}
```

**Source model signal pattern** (lines 122-135):
```cpp
delete m_root;
m_items.clear();

m_root = new TabMruModelItem;
sourceRowsInserted(QModelIndex(), 0, sourceModel()->rowCount());
currentTabChanged(m_window->tabWidget()->currentIndex());

connect(m_window->tabWidget(), &TabWidget::currentChanged, this, &TabMruModel::currentTabChanged, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &TabMruModel::sourceDataChanged, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::rowsInserted, this, &TabMruModel::sourceRowsInserted, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::rowsAboutToBeRemoved, this, &TabMruModel::sourceRowsAboutToBeRemoved, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::modelReset, this, &TabMruModel::sourceReset, Qt::UniqueConnection);
```

**Current tab to top pattern** (lines 151-161):
```cpp
TabMruModelItem *it = item(mapFromSource(sourceModel()->index(index, 0)));
if (!it) {
    return;
}
const int from = m_root->children.indexOf(it);
if (from == 0) {
    return;
}
if (!beginMoveRows(QModelIndex(), from, from, QModelIndex(), 0)) {
```

Apply:
- Quick switch must use `BrowserWindow::tabMruModel()` as the source/order.
- Filtering can wrap `TabMruModel` in a proxy, but typed filtering must not mutate MRU order.

---

### `falkon/src/lib/tabwidget/tabgroupmodel.{h,cpp}` or tab group metadata extension (model, CRUD/event-driven)

**Analogs:** `falkon/src/lib/tabwidget/tabtreemodel.cpp`, `falkon/src/plugins/VerticalTabs/verticaltabswidget.cpp`

**Tree proxy initialization pattern** (lines 255-280):
```cpp
delete m_root;
m_items.clear();

m_root = new TabTreeModelItem;

for (int i = 0; i < sourceModel()->rowCount(); ++i) {
    const QModelIndex index = sourceModel()->index(i, 0);
    auto *tab = index.data(TabModel::WebTabRole).value<WebTab*>();
    if (tab && !tab->parentTab()) {
        auto *item = new TabTreeModelItem(tab, index);
        m_items[tab] = item;
        m_root->addChild(createItems(item));
    }
}

for (TabTreeModelItem *item : std::as_const(m_items)) {
    connectTab(item->tab);
}

connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &TabTreeModel::sourceDataChanged, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::rowsInserted, this, &TabTreeModel::sourceRowsInserted, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::rowsAboutToBeRemoved, this, &TabTreeModel::sourceRowsAboutToBeRemoved, Qt::UniqueConnection);
connect(sourceModel(), &QAbstractItemModel::modelReset, this, &TabTreeModel::sourceReset, Qt::UniqueConnection);
```

**Existing group menu pattern from VerticalTabs** (lines 232-249):
```cpp
m_groupMenu->clear();

for (int i = 0; i < m_window->tabWidget()->count(); ++i) {
    WebTab *tab = m_window->tabWidget()->webTab(i);
    if (tab->url().toString(QUrl::RemoveFragment) == QL1S("extension://verticaltabs/group")) {
        m_groupMenu->addAction(tab->url().fragment(), this, [=]() {
            QMetaObject::invokeMethod(m_window, "addTab");
            m_window->tabWidget()->webTab()->setParentTab(tab);
        });
    }
}

m_groupMenu->addSeparator();
m_groupMenu->addAction(tr("Add New Group..."), this, [this]() {
    m_window->tabWidget()->addView(QUrl(QSL("extension://verticaltabs/group")), Qz::NT_SelectedTab);
});
```

Apply:
- Native tab groups should be metadata in model/session state, not extension URL pseudo-tabs.
- If a tree/group model is added, follow the `TabTreeModel` proxy pattern over `TabModel`.
- Preserve drag/drop by delegating moves back through `TabModel::dropMimeData()` or `TabWidget::tabBar()->moveTab()`.

---

### `falkon/src/lib/tabwidget/taboverviewpopup.{h,cpp}` or `tabsearchpopup.{h,cpp}` (component, search/filter/action UI)

**Analogs:** `falkon/src/plugins/TabManager/tabmanagerwidget.cpp`, `falkon/src/plugins/VerticalTabs/verticaltabswidget.cpp`, `falkon/src/plugins/VerticalTabs/tabfiltermodel.cpp`

**Model-backed dense view setup** (VerticalTabs lines 44-50):
```cpp
m_pinnedView = new TabListView(m_window, this);
auto *model = new TabFilterModel(m_pinnedView);
model->setFilterPinnedTabs(false);
model->setRejectDropOnLastIndex(true);
model->setSourceModel(m_window->tabModel());
m_pinnedView->setModel(model);
m_pinnedView->setHideWhenEmpty(true);
```

**Proxy filter pattern** (`tabfiltermodel.cpp` lines 22-60):
```cpp
TabFilterModel::TabFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}
...
const QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
return index.data(TabModel::PinnedRole).toBool() != m_filterPinnedTabs;
...
return QSortFilterProxyModel::canDropMimeData(data, action, row, column, parent);
```

**Text filter pattern** (TabManager lines 340-390):
```cpp
m_filterText = filter.simplified();
ui->treeWidget->itemDelegate()->setProperty("filterText", m_filterText);
if (m_filterText.isEmpty()) {
    for (int i = 0; i < ui->treeWidget->topLevelItemCount(); ++i) {
        QTreeWidgetItem* parentItem = ui->treeWidget->topLevelItem(i);
        for (int j = 0; j < parentItem->childCount(); ++j) {
            QTreeWidgetItem* childItem = parentItem->child(j);
            childItem->setHidden(false);
        }
        parentItem->setHidden(false);
        parentItem->setExpanded(true);
    }
    return;
}

const QRegularExpression filterRegExp(filter.simplified().replace(QL1C(' '), QLatin1String(".*"))
                                      .append(QLatin1String(".*")).prepend(QLatin1String(".*")),
                                      QRegularExpression::CaseInsensitiveOption);
```

**Keyboard search/navigation pattern** (TabManager lines 400-435):
```cpp
if (obj == ui->treeWidget) {
    if (keyEvent->key() == Qt::Key_Enter || keyEvent->key() == Qt::Key_Return) {
        onItemActivated(ui->treeWidget->currentItem(), 0);
        return QObject::eventFilter(obj, event);
    }

    if (!text.isEmpty() || ((keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() == Qt::Key_F)) {
        ui->filterBar->show();
        ui->treeWidget->setFocusProxy(ui->filterBar);
        ui->filterBar->setFocus();
        if (!text.isEmpty() && text.at(0).isPrint()) {
            ui->filterBar->setText(ui->filterBar->text() + text);
        }
        return true;
    }
}
else if (obj == ui->filterBar) {
    bool isNavigationOrActionKey = keyEvent->key() == Qt::Key_Up ||
            keyEvent->key() == Qt::Key_Down ||
            keyEvent->key() == Qt::Key_PageDown ||
            keyEvent->key() == Qt::Key_PageUp ||
            keyEvent->key() == Qt::Key_Enter ||
            keyEvent->key() == Qt::Key_Return;

    if (isNavigationOrActionKey) {
        QKeyEvent ev(QKeyEvent::KeyPress, keyEvent->key(), keyEvent->modifiers());
        QApplication::sendEvent(ui->treeWidget, &ev);
        return false;
    }
}
```

**Row activation pattern** (TabManager lines 231-258):
```cpp
BrowserWindow* mainWindow = tabItem->window();
QWidget* tabWidget = tabItem->webTab();
...
mainWindow->show();
mainWindow->activateWindow();
mainWindow->raise();
mainWindow->weView()->setFocus();

if (tabWidget && tabWidget != mainWindow->tabWidget()->currentWidget()) {
    mainWindow->tabWidget()->setCurrentIndex(mainWindow->tabWidget()->indexOf(tabWidget));
}
```

Apply:
- Prefer `QListView`/`QTreeView` + `QSortFilterProxyModel` over `QTreeWidget` for new code because `TabModel` already exists.
- Rows must be 32px per `07-UI-SPEC.md`.
- Empty state copy must be exactly from UI spec: `No tabs found` and `Clear the search or open a new tab group.`

---

### `falkon/src/lib/tabwidget/tabcontextmenu.{h,cpp}` (component/controller, request-response actions)

**Analog:** `falkon/src/lib/tabwidget/tabcontextmenu.{h,cpp}`

**Options/header pattern** (header lines 33-44):
```cpp
enum Option {
    InvalidOption = 0,
    HorizontalTabs = 1 << 0,
    VerticalTabs = 1 << 1,
    ShowCloseOtherTabsActions = 1 << 2,
    ShowDetachTabAction = 1 << 3,

    DefaultOptions = HorizontalTabs | ShowCloseOtherTabsActions | ShowDetachTabAction
};
Q_DECLARE_FLAGS(Options, Option)

explicit TabContextMenu(int index, BrowserWindow *window, Options options = DefaultOptions);
```

**Signal wiring pattern** (lines 38-49):
```cpp
TabWidget *tabWidget = m_window->tabWidget();
connect(this, &TabContextMenu::tabCloseRequested, tabWidget->tabBar(), &ComboTabBar::tabCloseRequested);
connect(this, SIGNAL(reloadTab(int)), tabWidget, SLOT(reloadTab(int)));
connect(this, SIGNAL(stopTab(int)), tabWidget, SLOT(stopTab(int)));
connect(this, SIGNAL(closeAllButCurrent(int)), tabWidget, SLOT(closeAllButCurrent(int)));
connect(this, SIGNAL(closeToRight(int)), tabWidget, SLOT(closeToRight(int)));
connect(this, SIGNAL(closeToLeft(int)), tabWidget, SLOT(closeToLeft(int)));
connect(this, SIGNAL(duplicateTab(int)), tabWidget, SLOT(duplicateTab(int)));
connect(this, SIGNAL(detachTab(int)), tabWidget, SLOT(detachTab(int)));
connect(this, SIGNAL(loadTab(int)), tabWidget, SLOT(loadTab(int)));
connect(this, SIGNAL(unloadTab(int)), tabWidget, SLOT(unloadTab(int)));
```

**Destructive confirmation pattern** (lines 53-75):
```cpp
Settings settings;
bool ask = settings.value(QSL("Browser-Tabs-Settings/") + settingsKey, true).toBool();

if (ask) {
    CheckBoxDialog dialog(QMessageBox::Yes | QMessageBox::No, mApp->activeWindow());
    dialog.setDefaultButton(QMessageBox::No);
    dialog.setWindowTitle(title);
    dialog.setText(description);
    dialog.setCheckBoxText(TabBar::tr("Don't ask again"));
    dialog.setIcon(QMessageBox::Question);

    if (dialog.exec() != QMessageBox::Yes) {
        return false;
    }

    if (dialog.isChecked()) {
        settings.setValue(QSL("Browser-Tabs-Settings/") + settingsKey, false);
    }
}

return true;
```

**Action list pattern** (lines 116-151):
```cpp
if (m_window->weView(m_clickedTab)->isLoading()) {
    addAction(QIcon::fromTheme(QSL("process-stop")), tr("&Stop Tab"), this, SLOT(stopTab()));
}
else {
    addAction(QIcon::fromTheme(QSL("view-refresh")), tr("&Reload Tab"), this, SLOT(reloadTab()));
}

addAction(QIcon::fromTheme(QSL("tab-duplicate")), tr("&Duplicate Tab"), this, SLOT(duplicateTab()));
...
addAction(webTab->isPinned() ? tr("Un&pin Tab") : tr("&Pin Tab"), this, &TabContextMenu::pinTab);
addAction(webTab->isMuted() ? tr("Un&mute Tab") : tr("&Mute Tab"), this, &TabContextMenu::muteTab);

if (!webTab->isRestored()) {
    addAction(tr("Load Tab"), this, SLOT(loadTab()));
} else {
    addAction(tr("Unload Tab"), this, SLOT(unloadTab()));
}
...
addAction(m_window->action(QSL("Other/RestoreClosedTab")));
addAction(QIcon::fromTheme(QSL("window-close")), tr("Cl&ose Tab"), this, &TabContextMenu::closeTab);
```

Apply:
- Overview/search context menus should instantiate `TabContextMenu` for existing actions.
- Group-close and close-other flows must use the same confirmation style, with copy from `07-UI-SPEC.md`.

---

### `falkon/src/lib/agent/agentcommandrouter.{h,cpp}` or read-only tab state provider (service, request-response/in-memory state)

**Analog:** `falkon/src/lib/agent/agentcommandrouter.{h,cpp}`

**Internal state pattern** (header lines 80-96):
```cpp
QString targetKey(int windowIndex, int tabIndex) const;
QJsonObject buildSupervisionSnapshot(const Target &target, QString* snapshotHash) const;
bool validateSupervisionSession(const QString &sessionId, const Target &target, QString* errorCode, QString* errorMessage) const;
QUrl taskUrlFromPrompt(const QString &prompt) const;
QString agentIdForParams(const QJsonObject &params, QString* errorCode, QString* errorMessage);
bool enforceOwnership(const QJsonObject &params, const Target &target, QString* agentId, QString* errorCode, QString* errorMessage);
QJsonObject visualDetails(const QJsonObject &params, const QString &agentId) const;
void showActionStatus(const Target &target, const QString &tool, const QString &agentId, const QJsonObject &params);
...
QHash<QString, QString> m_agentIds;
QHash<QString, QString> m_tabOwners;
QHash<QString, QJsonObject> m_supervisionSessions;
```

**Ownership assignment pattern** (lines 471-480):
```cpp
const QString rawUrl = params.value(QSL("url")).toString();
const QUrl url = rawUrl.isEmpty() ? QUrl() : QUrl::fromUserInput(rawUrl);
const int tabIndex = windows.at(windowIndex)->tabWidget()->addView(url, Qz::NT_SelectedTabAtTheEnd);
m_tabOwners.insert(targetKey(windowIndex, tabIndex), agentId);
Target target;
target.window = windows.at(windowIndex);
target.windowIndex = windowIndex;
target.tabIndex = tabIndex;
showActionStatus(target, tool, agentId, params);
return success(id, tool, QJsonObject{{QSL("windowIndex"), windowIndex}, {QSL("tabIndex"), tabIndex}, {QSL("url"), url.toString()}, {QSL("agentId"), agentId}, {QSL("visual"), visualDetails(params, agentId)}}, auditSequence);
```

**Supervision session pattern** (lines 1113-1132):
```cpp
QString snapshotHash;
QJsonObject snapshot = buildSupervisionSnapshot(target, &snapshotHash);
const QString sessionId = QUuid::createUuid().toString(QUuid::WithoutBraces);
const QString pairingCode = QUuid::createUuid().toString(QUuid::Id128).left(8).toUpper();
const QJsonObject targetJson{{QSL("windowIndex"), target.windowIndex}, {QSL("tabIndex"), target.tabIndex}, {QSL("key"), targetKey(target.windowIndex, target.tabIndex)}};
QJsonObject session{
    {QSL("sessionId"), sessionId},
    {QSL("pairingCode"), pairingCode},
    {QSL("agentId"), agentId},
    {QSL("target"), targetJson},
    {QSL("createdAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)},
    {QSL("expiresAt"), QDateTime::currentDateTimeUtc().addSecs(600).toString(Qt::ISODateWithMs)},
    {QSL("sequence"), 1},
    {QSL("lastHash"), snapshotHash}
};
m_supervisionSessions.insert(sessionId, session);
```

**Ownership enforcement pattern** (lines 1349-1369):
```cpp
const QString key = targetKey(target.windowIndex, target.tabIndex);
const QString owner = m_tabOwners.value(key);
if (owner.isEmpty()) {
    m_tabOwners.insert(key, *agentId);
    return true;
}

if (owner != *agentId) {
    *errorCode = QSL("TAB_OWNED_BY_OTHER_AGENT");
    *errorMessage = QSL("Target tab is owned by another agent.");
    return false;
}

return true;
```

**Status-only UI pattern today** (lines 1383-1394):
```cpp
void AgentCommandRouter::showActionStatus(const Target &target, const QString &tool, const QString &agentId, const QJsonObject &params)
{
    if (!target.window || !target.window->statusBar()) {
        return;
    }

    QString reason = params.value(QSL("visual_reason")).toString(params.value(QSL("visualReason")).toString());
    if (reason.isEmpty()) {
        reason = tool;
    }
    target.window->statusBar()->showMessage(QSL("%1 controlling Prometheus: %2").arg(agentId, reason), 3000);
}
```

Apply:
- Add read-only helpers or a small provider that answers owner, active automation, supervision, and health for `(windowIndex, tabIndex)`/`WebTab*`.
- Do not expose private maps to paint code.
- Any agent-owned destructive action UI must surface ownership before close/unload/detach/move.

---

### `falkon/src/lib/CMakeLists.txt` and plugin CMake files (config/build graph)

**Analog:** `falkon/src/lib/CMakeLists.txt`

**Library source list pattern** (lines 233-241):
```cmake
tabwidget/combotabbar.cpp
tabwidget/tabbar.cpp
tabwidget/tabicon.cpp
tabwidget/tabmodel.cpp
tabwidget/tabmrumodel.cpp
tabwidget/tabtreemodel.cpp
tabwidget/tabstackedwidget.cpp
tabwidget/tabwidget.cpp
tabwidget/tabcontextmenu.cpp
```

**Library header list pattern** (lines 474-482):
```cmake
tabwidget/combotabbar.h
tabwidget/tabbar.h
tabwidget/tabicon.h
tabwidget/tabmodel.h
tabwidget/tabmrumodel.h
tabwidget/tabtreemodel.h
tabwidget/tabstackedwidget.h
tabwidget/tabwidget.h
tabwidget/tabcontextmenu.h
```

**UI list pattern** (lines 571-578):
```cmake
preferences/acceptlanguage.ui
preferences/addacceptlanguage.ui
preferences/autofillmanager.ui
preferences/autoopenprotocolsdialog.ui
preferences/certificatemanager.ui
preferences/jsoptions.ui
preferences/pluginslist.ui
preferences/preferences.ui
```

**Plugin source pattern for reference only** (`TabManager/CMakeLists.txt` lines 1-14):
```cmake
set( TabManager_SRCS
    tabmanagerplugin.cpp
    tabmanagerwidget.cpp
    tabmanagerwidgetcontroller.cpp
    tabmanagersettings.cpp
    tabmanagerdelegate.cpp
    tldextractor/tldextractor.cpp
        tabmanagerplugin.h
        tabmanagerwidget.h
        tabmanagerwidgetcontroller.h
        tabmanagersettings.h
        tabmanagerdelegate.h
        tldextractor/tldextractor.h
        )
```

Apply:
- Any new lib class must be added to both source and header lists.
- Do not put phase-core compact chrome into plugin CMake files unless the implementation intentionally stays plugin-scoped.

---

### `falkon/autotests/tabmodeltest.cpp` (test, model events/CRUD)

**Analog:** `falkon/autotests/tabmodeltest.cpp`

**Model test setup pattern** (lines 38-68):
```cpp
BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

TabModel model1(w);
ModelTest modelTest(&model1);

QSignalSpy rowsInsertedSpy(&model1, &TabModel::rowsInserted);
QSignalSpy rowsRemovedSpy(&model1, &TabModel::rowsRemoved);

QCOMPARE(model1.rowCount(), 0);

rowsInsertedSpy.wait();

QCOMPARE(rowsInsertedSpy.count(), 1);
WebTab *tab0 = w->tabWidget()->webTab(0);
...
QCOMPARE(model1.data(model1.index(0, 0), TabModel::WebTabRole).value<WebTab*>(), tab0);
```

**Role data test pattern** (lines 100-117):
```cpp
BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);
TabModel model(w);
ModelTest modelTest(&model);

QTRY_COMPARE(model.rowCount(), 1);

WebTab *tab0 = w->tabWidget()->webTab(0);
QCOMPARE(model.index(0, 0).data(TabModel::TitleRole).toString(), tab0->title());
QCOMPARE(model.index(0, 0).data(Qt::DisplayRole).toString(), tab0->title());
QCOMPARE(model.index(0, 0).data(TabModel::IconRole).value<QIcon>().pixmap(16), tab0->icon().pixmap(16));
QCOMPARE(model.index(0, 0).data(Qt::DecorationRole).value<QIcon>().pixmap(16), tab0->icon().pixmap(16));
QCOMPARE(model.index(0, 0).data(TabModel::PinnedRole).toBool(), tab0->isPinned());
QCOMPARE(model.index(0, 0).data(TabModel::RestoredRole).toBool(), tab0->isRestored());
QCOMPARE(model.index(0, 0).data(TabModel::CurrentTabRole).toBool(), true);
```

**MRU test pattern** (lines 258-314):
```cpp
BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

TabModel sourceModel(w);
TabMruModel model(w);
model.setSourceModel(&sourceModel);
ModelTest modelTest(&model);

w->tabWidget()->addView(QUrl());
...
QTRY_COMPARE(model.rowCount(QModelIndex()), 6);
...
w->tabWidget()->setCurrentIndex(2);
QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
...
delete w;
```

Apply:
- Add tests for new `TabModel` roles, group metadata moves, and MRU quick-switch filtering behavior.
- Use `ModelTest` for new proxy models.

---

### `falkon/autotests/locationbartest.cpp` (test, parser transform)

**Analog:** `falkon/autotests/locationbartest.cpp`

**Parser test pattern** (lines 48-81):
```cpp
LocationBar::LoadAction action;

action = LocationBar::loadAction(QSL("http://kde.org"));
QCOMPARE(action.type, LocationBar::LoadAction::Url);
QCOMPARE(action.loadRequest.url(), QUrl(QSL("http://kde.org")));

action = LocationBar::loadAction(QSL("kde.org"));
QCOMPARE(action.type, LocationBar::LoadAction::Url);
QCOMPARE(action.loadRequest.url(), QUrl(QSL("http://kde.org")));
...
action = LocationBar::loadAction(QSL("not-url"));
QCOMPARE(action.type, LocationBar::LoadAction::Search);
```

**Search engine setup pattern** (lines 106-123):
```cpp
SearchEngine engine;
engine.name = QSL("Test Engine");
engine.url = QSL("http://test/%s");
engine.shortcut = QSL("t");
mApp->searchEnginesManager()->addEngine(engine);
mApp->searchEnginesManager()->setDefaultEngine(engine);

LocationBar::LoadAction action;

action = LocationBar::loadAction(QSL("search term"));
QCOMPARE(action.type, LocationBar::LoadAction::Search);
QCOMPARE(action.loadRequest.url(), QUrl(QSL("http://test/search%20term")));
```

Apply:
- If compact active tab/address touches URL/search behavior, extend this test rather than adding UI-only assertions.
- If compact mode only wraps `LocationBar`, no parser test should be needed.

## Shared Patterns

### Settings Reload

**Sources:** `falkon/src/lib/app/mainapplication.cpp`, `falkon/src/lib/tabwidget/tabwidget.cpp`, `falkon/src/lib/navigation/locationbar.cpp`

**Reload signal source** (MainApplication lines 598-601):
```cpp
void MainApplication::reloadSettings()
{
    loadSettings();
    Q_EMIT settingsReloaded();
}
```

**Listeners**:
```cpp
// tabwidget.cpp lines 103 and 171
connect(mApp, &MainApplication::settingsReloaded, this, &TabWidget::loadSettings);
m_tabBar->loadSettings();

// locationbar.cpp lines 105-107
connect(mApp, &MainApplication::settingsReloaded, this, &LocationBar::loadSettings);
loadSettings();
```

**Apply to:** `TabWidget`, `TabBar`, compact strip, navigation bar compact/separate switch, and any settings-backed tab overview/search option.

### Active Address/Search Reuse

**Sources:** `NavigationBar`, `TabWidget`, `BrowserWindow`, `LocationBar`

```cpp
// navigationbar.cpp lines 157-159
m_navigationSplitter = new QSplitter(this);
m_navigationSplitter->addWidget(m_window->tabWidget()->locationBars());
m_navigationSplitter->addWidget(m_searchLine);

// tabwidget.cpp lines 514-518
LocationBar* locBar = webTab->locationBar();
if (locBar && m_locationBars->indexOf(locBar) != -1) {
    m_locationBars->setCurrentWidget(locBar);
}

// browserwindow.cpp lines 1188-1193
if (isFullScreen()) {
    showNavigationWithFullScreen();
}
locationBar()->setFocus();
locationBar()->selectAll();
```

**Apply to:** compact active tab/address. The active compact field must remain the current tab's `LocationBar`.

### Existing Tab Actions

**Sources:** `TabWidget`, `TabContextMenu`, `MainMenu`

```cpp
// tabcontextmenu.cpp lines 45-48
connect(this, SIGNAL(duplicateTab(int)), tabWidget, SLOT(duplicateTab(int)));
connect(this, SIGNAL(detachTab(int)), tabWidget, SLOT(detachTab(int)));
connect(this, SIGNAL(loadTab(int)), tabWidget, SLOT(loadTab(int)));
connect(this, SIGNAL(unloadTab(int)), tabWidget, SLOT(unloadTab(int)));

// mainmenu.cpp lines 611-615
action = new QAction(QIcon::fromTheme(QSL("user-trash")), tr("Restore &Closed Tab"), this);
action->setShortcut(QKeySequence(QSL("Ctrl+Shift+T")));
connect(action, &QAction::triggered, this, &MainMenu::restoreClosedTab);
m_actions[QSL("Other/RestoreClosedTab")] = action;
```

**Apply to:** compact tab context menus, overview rows, search rows, quick switch, group operations.

### Dense Native Rows

**Sources:** `VerticalTabs` and `TabManager`

```cpp
// tablistdelegate.cpp lines 85-113
const int iconSize = 16;
...
painter->drawPixmap(iconRect, pixmap);
...
QString title = opt.fontMetrics.elidedText(index.data().toString(), Qt::ElideRight, titleRect.width());
style->drawItemText(painter, titleRect, Qt::AlignLeft, textPalette, true, title, colorRole);

// tabmanagerwidget.cpp lines 359-361
const QRegularExpression filterRegExp(filter.simplified().replace(QL1C(' '), QLatin1String(".*"))
                                      .append(QLatin1String(".*")).prepend(QLatin1String(".*")),
                                      QRegularExpression::CaseInsensitiveOption);
```

**Apply to:** Tab Overview, Search Tabs, quick switch. Keep rows native, compact, and model-driven.

### Agent State Boundaries

**Source:** `AgentCommandRouter`

```cpp
// agentcommandrouter.cpp lines 1356-1366
const QString key = targetKey(target.windowIndex, target.tabIndex);
const QString owner = m_tabOwners.value(key);
if (owner.isEmpty()) {
    m_tabOwners.insert(key, *agentId);
    return true;
}

if (owner != *agentId) {
    *errorCode = QSL("TAB_OWNED_BY_OTHER_AGENT");
    *errorMessage = QSL("Target tab is owned by another agent.");
    return false;
}
```

**Apply to:** badge rendering, destructive action confirmations, overview/search row state. Add a read-only query API rather than accessing private maps from UI paint code.

### Build and Test Registration

**Sources:** `falkon/src/lib/CMakeLists.txt`, `falkon/autotests/CMakeLists.txt`

```cmake
# lib CMakeLists.txt lines 233-241
tabwidget/combotabbar.cpp
tabwidget/tabbar.cpp
tabwidget/tabicon.cpp
tabwidget/tabmodel.cpp
tabwidget/tabmrumodel.cpp
tabwidget/tabtreemodel.cpp
tabwidget/tabstackedwidget.cpp
tabwidget/tabwidget.cpp
tabwidget/tabcontextmenu.cpp

# autotests CMakeLists.txt lines 7-13
macro(falkon_tests)
    foreach(_testname ${ARGN})
        add_executable(${_testname} ${_testname}.cpp ${_testname}.h ${falkon_autotests_SRCS})
        target_link_libraries(${_testname} Qt::Test FalkonPrivate)
        add_test(NAME falkon-${_testname} COMMAND ${_testname})
        ecm_mark_as_test(${_testname})
        set_tests_properties(falkon-${_testname} PROPERTIES RUN_SERIAL TRUE)
```

**Apply to:** new tabwidget/navigation files and model tests.

## No Analog Found

No likely Phase 07 file or component area lacks a local analog. The weakest match is full native tab groups because current grouping exists as `VerticalTabs` extension pseudo-tabs and `TabTreeModel` parent/child relationships, not first-class browser tab group metadata. Planner should treat tab group persistence as a higher-risk design area and require explicit acceptance checks.

## Metadata

**Analog search scope:** `falkon/src/lib/app`, `falkon/src/lib/navigation`, `falkon/src/lib/tabwidget`, `falkon/src/lib/preferences`, `falkon/src/lib/other`, `falkon/src/lib/agent`, `falkon/src/plugins/TabManager`, `falkon/src/plugins/VerticalTabs`, `falkon/autotests`, and relevant CMake files.

**Files scanned:** 35

**Pattern extraction date:** 2026-06-16

## PATTERN MAPPING COMPLETE
