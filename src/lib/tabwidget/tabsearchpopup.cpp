/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2026 Prometheus Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* ============================================================ */
#include "tabsearchpopup.h"
#include "browserwindow.h"
#include "tabmrumodel.h"
#include "tabmodel.h"
#include "tabsearchdelegate.h"
#include "tabsearchfiltermodel.h"
#include "tabwidget.h"
#include "webtab.h"
#include "checkboxdialog.h"
#include "mainapplication.h"
#include "settings.h"
#include "tabgroupmodel.h"
#include "agent/prometheusiconresolver.h"

#include <QAbstractItemModel>
#include <QAction>
#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QEvent>
#include <QHBoxLayout>
#include <QInputDialog>
#include <QKeyEvent>
#include <QLabel>
#include <QLineEdit>
#include <QListView>
#include <QMenu>
#include <QMessageBox>
#include <QPersistentModelIndex>
#include <QPointer>
#include <QSet>
#include <QSize>
#include <QSignalBlocker>
#include <QStackedWidget>
#include <QStyle>
#include <QTimer>
#include <QToolButton>
#include <QVBoxLayout>

namespace {
constexpr int PopupWidth = 520;
constexpr int PopupMaxHeight = 420;
constexpr int PopupPadding = 8;
constexpr int PopupSpacing = 4;
constexpr int EmptyStateIndex = 0;
constexpr int ListStateIndex = 1;

bool isNavigationKey(int key)
{
    return key == Qt::Key_Up
            || key == Qt::Key_Down
            || key == Qt::Key_PageUp
            || key == Qt::Key_PageDown
            || key == Qt::Key_Home
            || key == Qt::Key_End;
}
}

TabSearchPopup::TabSearchPopup(BrowserWindow *window, QWidget *parent)
    : QFrame(parent, Qt::Popup)
    , m_window(window)
    , m_filterModel(new TabSearchFilterModel(this))
    , m_delegate(new TabSearchDelegate(this))
    , m_searchEdit(new QLineEdit(this))
    , m_mruOrder(new QCheckBox(tr("MRU"), this))
    , m_groupFilter(new QComboBox(this))
    , m_groupActions(new QToolButton(this))
    , m_view(new QListView(this))
    , m_titleLabel(new QLabel(this))
    , m_emptyTitle(new QLabel(tr("No tabs found"), this))
    , m_emptyBody(new QLabel(tr("Clear the search or open a new tab group."), this))
    , m_stack(new QStackedWidget(this))
{
    setObjectName(QSL("TabSearchPopup"));
    setFrameShape(QFrame::StyledPanel);
    setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Maximum);

    m_titleLabel->setObjectName(QSL("tabSearchPopupTitle"));
    QFont titleFont = m_titleLabel->font();
    titleFont.setWeight(QFont::DemiBold);
    m_titleLabel->setFont(titleFont);

    m_searchEdit->setClearButtonEnabled(true);
    m_searchEdit->setPlaceholderText(tr("Search Tabs"));
    m_searchEdit->installEventFilter(this);

    m_mruOrder->setToolTip(tr("Use most recently used tab order"));
    connect(m_mruOrder, &QCheckBox::toggled, this, &TabSearchPopup::updateSourceModel);

    m_groupFilter->addItem(tr("All Groups"), QString());
    m_groupFilter->addItem(tr("Ungrouped"), TabSearchFilterModel::ungroupedGroupFilter());
    m_groupFilter->setVisible(false);
    connect(m_groupFilter, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int index) {
        m_filterModel->setGroupFilter(m_groupFilter->itemData(index).toString());
        updateEmptyState();
        selectFirstVisibleRow();
    });

    auto *groupActionsMenu = new QMenu(m_groupActions);
    m_groupActions->setText(tr("New Tab Group"));
    m_groupActions->setIcon(PrometheusIconResolver::icon(QSL("tab-group")));
    m_groupActions->setIconSize(QSize(14, 14));
    m_groupActions->setToolTip(tr("New Tab Group"));
    m_groupActions->setAccessibleName(tr("New Tab Group"));
    m_groupActions->setPopupMode(QToolButton::InstantPopup);
    m_groupActions->setMenu(groupActionsMenu);
    connect(groupActionsMenu, &QMenu::aboutToShow, this, [this, groupActionsMenu]() {
        populateGlobalGroupMenu(groupActionsMenu);
    });

    auto *headerLayout = new QHBoxLayout;
    headerLayout->setContentsMargins(0, 0, 0, 0);
    headerLayout->setSpacing(PopupSpacing);
    headerLayout->addWidget(m_titleLabel, 1);
    headerLayout->addWidget(m_mruOrder);
    headerLayout->addWidget(m_groupFilter);
    headerLayout->addWidget(m_groupActions);

    m_view->setObjectName(QSL("tabSearchPopupView"));
    m_view->setModel(m_filterModel);
    m_view->setItemDelegate(m_delegate);
    m_view->setUniformItemSizes(true);
    m_view->setFrameShape(QFrame::NoFrame);
    m_view->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_view->setSelectionMode(QAbstractItemView::SingleSelection);
    m_view->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_view->setVerticalScrollMode(QAbstractItemView::ScrollPerPixel);
    m_view->setContextMenuPolicy(Qt::CustomContextMenu);
    m_view->installEventFilter(this);
    connect(m_view, &QListView::activated, this, &TabSearchPopup::activateCurrentIndex);
    connect(m_view, &QWidget::customContextMenuRequested, this, &TabSearchPopup::showRowMenu);

    auto *emptyWidget = new QWidget(this);
    auto *emptyLayout = new QVBoxLayout(emptyWidget);
    emptyLayout->setContentsMargins(PopupPadding, PopupPadding * 2, PopupPadding, PopupPadding * 2);
    emptyLayout->setSpacing(PopupSpacing);
    emptyLayout->addStretch();
    emptyLayout->addWidget(m_emptyTitle, 0, Qt::AlignHCenter);
    emptyLayout->addWidget(m_emptyBody, 0, Qt::AlignHCenter);
    emptyLayout->addStretch();

    QFont emptyTitleFont = m_emptyTitle->font();
    emptyTitleFont.setWeight(QFont::DemiBold);
    m_emptyTitle->setFont(emptyTitleFont);
    m_emptyBody->setWordWrap(true);
    m_emptyBody->setAlignment(Qt::AlignCenter);

    m_stack->addWidget(emptyWidget);
    m_stack->addWidget(m_view);

    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(PopupPadding, PopupPadding, PopupPadding, PopupPadding);
    layout->setSpacing(PopupSpacing);
    layout->addLayout(headerLayout);
    layout->addWidget(m_searchEdit);
    layout->addWidget(m_stack);

    connect(m_searchEdit, &QLineEdit::textChanged, this, [this](const QString &text) {
        m_filterModel->setFilterText(text);
        updateEmptyState();
        selectFirstVisibleRow();
    });

    const auto updateAfterModelChange = [this]() {
        updateEmptyState();
        selectFirstVisibleRow();
    };
    connect(m_filterModel, &QAbstractItemModel::rowsInserted, this, [updateAfterModelChange](const QModelIndex &, int, int) {
        updateAfterModelChange();
    });
    connect(m_filterModel, &QAbstractItemModel::rowsRemoved, this, [updateAfterModelChange](const QModelIndex &, int, int) {
        updateAfterModelChange();
    });
    connect(m_filterModel, &QAbstractItemModel::modelReset, this, updateAfterModelChange);
    connect(m_filterModel, &QAbstractItemModel::layoutChanged, this, [updateAfterModelChange](const QList<QPersistentModelIndex> &, QAbstractItemModel::LayoutChangeHint) {
        updateAfterModelChange();
    });

    setMode(OverviewMode);
    resize(PopupWidth, sizeHint().height());
}

TabSearchPopup::Mode TabSearchPopup::mode() const
{
    return m_mode;
}

void TabSearchPopup::setMode(Mode mode)
{
    m_mode = mode;

    if (m_mode == QuickSwitchMode) {
        m_titleLabel->setText(tr("Search Tabs"));
        m_mruOrder->setChecked(true);
        m_mruOrder->setEnabled(false);
        m_groupFilter->setCurrentIndex(0);
    } else {
        m_titleLabel->setText(m_mode == OverviewMode ? tr("Tab Overview") : tr("Search Tabs"));
        m_mruOrder->setEnabled(true);
    }

    m_filterModel->setGroupSectionsEnabled(m_mode == OverviewMode);
    updateSourceModel();
    updateGroupFilterVisibility();
    updateEmptyState();
    selectFirstVisibleRow();
}

void TabSearchPopup::setGroupFilters(const QStringList &groups)
{
    const QString previous = m_groupFilter->currentData().toString();
    QSignalBlocker blocker(m_groupFilter);
    m_groupFilter->clear();
    m_groupFilter->addItem(tr("All Groups"), QString());
    m_groupFilter->addItem(tr("Ungrouped"), TabSearchFilterModel::ungroupedGroupFilter());
    for (const QString &group : groups) {
        const QString normalized = group.simplified();
        if (!normalized.isEmpty()) {
            m_groupFilter->addItem(normalized, normalized);
        }
    }

    const int index = m_groupFilter->findData(previous);
    m_groupFilter->setCurrentIndex(index >= 0 ? index : 0);
    blocker.unblock();
    m_filterModel->setGroupFilter(m_groupFilter->currentData().toString());
    updateGroupFilterVisibility();
}

void TabSearchPopup::showOverview()
{
    setMode(OverviewMode);
    show();
}

void TabSearchPopup::showSearch()
{
    setMode(SearchMode);
    show();
}

void TabSearchPopup::showQuickSwitch()
{
    setMode(QuickSwitchMode);
    show();
}

void TabSearchPopup::popup(const QPoint &globalPosition)
{
    move(globalPosition);
    show();
}

bool TabSearchPopup::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::KeyPress) {
        auto *keyEvent = static_cast<QKeyEvent*>(event);

        if (keyEvent->key() == Qt::Key_Escape) {
            close();
            return true;
        }

        if (keyEvent->key() == Qt::Key_Return || keyEvent->key() == Qt::Key_Enter) {
            activateCurrentIndex();
            return true;
        }

        if (watched == m_searchEdit && isNavigationKey(keyEvent->key())) {
            routeNavigationKey(keyEvent);
            return true;
        }

        if (watched == m_view) {
            if ((keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() == Qt::Key_F) {
                m_searchEdit->setFocus();
                m_searchEdit->selectAll();
                return true;
            }

            const QString text = keyEvent->text();
            if (!text.isEmpty() && text.at(0).isPrint()) {
                m_searchEdit->setFocus();
                m_searchEdit->setText(m_searchEdit->text() + text);
                return true;
            }
        }
    }

    return QFrame::eventFilter(watched, event);
}

void TabSearchPopup::showEvent(QShowEvent *event)
{
    QFrame::showEvent(event);

    setFixedWidth(PopupWidth);
    setMaximumHeight(PopupMaxHeight);
    updateSourceModel();
    updateEmptyState();
    selectFirstVisibleRow();

    if (m_mode == SearchMode || m_mode == QuickSwitchMode) {
        m_searchEdit->setFocus();
        m_searchEdit->selectAll();
    } else {
        m_view->setFocus();
    }
}

void TabSearchPopup::updateSourceModel()
{
    if (!m_window) {
        m_filterModel->setSourceModel(nullptr);
        return;
    }

    QAbstractItemModel *sourceModel = nullptr;
    if (m_mode == QuickSwitchMode || m_mruOrder->isChecked()) {
        sourceModel = m_window->tabMruModel();
    } else {
        sourceModel = m_window->tabModel();
    }
    m_filterModel->setMruModel(m_window->tabMruModel());
    if (m_filterModel->sourceModel() != sourceModel) {
        m_filterModel->setSourceModel(sourceModel);
    }
    populateGroupFilter();
}

void TabSearchPopup::populateGroupFilter()
{
    const QString previous = m_groupFilter->currentData().toString();
    QSignalBlocker blocker(m_groupFilter);
    m_groupFilter->clear();
    m_groupFilter->addItem(tr("All Groups"), QString());

    QSet<QString> seenGroups;
    bool hasUngrouped = false;
    if (m_window && m_window->tabModel()) {
        TabModel *model = m_window->tabModel();
        const int rows = model->rowCount();
        for (int row = 0; row < rows; ++row) {
            const QModelIndex index = model->index(row, 0);
            const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
            if (groupId.isEmpty()) {
                hasUngrouped = true;
                continue;
            }

            if (seenGroups.contains(groupId)) {
                continue;
            }
            seenGroups.insert(groupId);

            QString groupName = index.data(TabModel::TabGroupNameRole).toString().simplified();
            if (groupName.isEmpty()) {
                groupName = tr("Tab Group");
            }
            const bool collapsed = index.data(TabModel::TabGroupCollapsedRole).toBool();
            m_groupFilter->addItem(collapsed ? tr("%1 (Collapsed)").arg(groupName) : groupName, groupId);
        }
    }

    if (hasUngrouped) {
        m_groupFilter->addItem(tr("Ungrouped"), TabSearchFilterModel::ungroupedGroupFilter());
    }

    const int index = m_groupFilter->findData(previous);
    m_groupFilter->setCurrentIndex(index >= 0 ? index : 0);
    blocker.unblock();
    m_filterModel->setGroupFilter(m_groupFilter->currentData().toString());
    updateGroupFilterVisibility();
}

void TabSearchPopup::updateGroupFilterVisibility()
{
    m_groupFilter->setVisible(m_mode != QuickSwitchMode && m_groupFilter->count() > 1);
}

void TabSearchPopup::updateEmptyState()
{
    const bool hasRows = m_filterModel->rowCount() > 0;
    m_stack->setCurrentIndex(hasRows ? ListStateIndex : EmptyStateIndex);
    m_view->setVisible(hasRows);
}

void TabSearchPopup::selectFirstVisibleRow()
{
    if (m_filterModel->rowCount() <= 0) {
        return;
    }

    const QModelIndex current = m_view->currentIndex();
    if (current.isValid() && current.row() < m_filterModel->rowCount()) {
        return;
    }

    m_view->setCurrentIndex(m_filterModel->index(0, 0));
}

void TabSearchPopup::activateCurrentIndex()
{
    WebTab *tab = currentTab();
    if (!tab) {
        return;
    }

    if (BrowserWindow *browserWindow = tab->browserWindow()) {
        if (browserWindow->isMinimized()) {
            browserWindow->showNormal();
        } else {
            browserWindow->show();
        }
        browserWindow->activateWindow();
        browserWindow->raise();
    }

    tab->makeCurrentTab();
    close();
}

void TabSearchPopup::routeNavigationKey(QKeyEvent *event)
{
    QKeyEvent copy(event->type(), event->key(), event->modifiers(), event->text(), event->isAutoRepeat(), event->count());
    QApplication::sendEvent(m_view, &copy);
}

WebTab *TabSearchPopup::currentTab() const
{
    const QModelIndex index = m_view->currentIndex();
    if (!index.isValid()) {
        return nullptr;
    }
    return index.data(TabModel::WebTabRole).value<WebTab*>();
}

void TabSearchPopup::showRowMenu(const QPoint &position)
{
    const QModelIndex index = m_view->indexAt(position);
    if (!index.isValid()) {
        return;
    }

    m_view->setCurrentIndex(index);
    WebTab *tab = index.data(TabModel::WebTabRole).value<WebTab*>();
    if (!tab) {
        return;
    }

    QMenu menu(this);
    populateTabActions(&menu, tab);
    menu.exec(m_view->viewport()->mapToGlobal(position));
}

void TabSearchPopup::populateTabActions(QMenu *menu, WebTab *tab)
{
    if (!menu || !tab || !m_window) {
        return;
    }

    addTabStateRows(menu, tab);

    TabWidget *tabWidget = m_window->tabWidget();
    const QPointer<WebTab> guardedTab(tab);

    QAction *duplicateAction = menu->addAction(QIcon::fromTheme(QSL("tab-duplicate")), tr("Duplicate Tab"));
    connect(duplicateAction, &QAction::triggered, this, [this, guardedTab]() {
        if (guardedTab && m_window) {
            m_window->tabWidget()->duplicateTab(guardedTab->tabIndex());
        }
    });

    if (mApp->windowCount() > 1 || tabWidget->count() > 1) {
        QAction *detachAction = menu->addAction(QIcon::fromTheme(QSL("tab-detach")), tr("Detach Tab"));
        connect(detachAction, &QAction::triggered, this, [this, guardedTab]() {
            if (guardedTab && m_window) {
                m_window->tabWidget()->detachTab(guardedTab->tabIndex());
            }
        });
    }

    QAction *loadAction = menu->addAction(tab->isRestored() ? tr("Unload Tab") : tr("Load Tab"));
    connect(loadAction, &QAction::triggered, this, [this, guardedTab]() {
        if (!guardedTab || !m_window) {
            return;
        }
        if (guardedTab->isRestored()) {
            m_window->tabWidget()->unloadTab(guardedTab->tabIndex());
        } else {
            m_window->tabWidget()->loadTab(guardedTab->tabIndex());
        }
    });

    menu->addSeparator();
    populateGroupActions(menu, tab);

    menu->addSeparator();
    QAction *restoreAction = menu->addAction(tr("Restore Closed Tab"));
    restoreAction->setEnabled(tabWidget->canRestoreTab());
    connect(restoreAction, &QAction::triggered, tabWidget, [tabWidget]() {
        tabWidget->restoreClosedTab();
    });

    QAction *clearAction = menu->addAction(QIcon::fromTheme(QSL("edit-clear")), tr("Clear Closed Tabs"));
    clearAction->setEnabled(tabWidget->canRestoreTab());
    connect(clearAction, &QAction::triggered, tabWidget, &TabWidget::requestClearClosedTabsList);

    menu->addSeparator();
    QAction *closeAction = menu->addAction(QIcon::fromTheme(QSL("window-close")), tr("Close Tab"));
    connect(closeAction, &QAction::triggered, this, [this, guardedTab]() {
        if (guardedTab && m_window) {
            m_window->tabWidget()->requestCloseTab(guardedTab->tabIndex());
            updateEmptyState();
            selectFirstVisibleRow();
        }
    });
}

void TabSearchPopup::populateGroupActions(QMenu *menu, WebTab *tab)
{
    if (!menu || !tab || !m_window) {
        return;
    }

    QAction *newGroupAction = menu->addAction(tr("New Tab Group"));
    connect(newGroupAction, &QAction::triggered, this, [this, tab]() {
        createTabGroup(tab);
    });

    QMenu *moveMenu = menu->addMenu(tr("Move Tab to Group"));
    populateMoveToGroupMenu(moveMenu, tab);

    const QString groupId = m_window->tabWidget()->tabGroupForTab(tab);
    if (groupId.isEmpty()) {
        return;
    }

    TabGroupModel *groups = m_window->tabWidget()->tabGroupModel();
    menu->addAction(tr("Rename Tab Group"), this, [this, groupId]() {
        renameTabGroup(groupId);
    });
    menu->addAction(groups->isGroupCollapsed(groupId) ? tr("Expand Tab Group") : tr("Collapse Tab Group"), this, [this, groupId]() {
        toggleTabGroupCollapsed(groupId);
    });
    menu->addAction(QIcon::fromTheme(QSL("window-close")), tr("Close Tab Group"), this, [this, groupId]() {
        closeTabGroup(groupId);
    });
}

void TabSearchPopup::populateMoveToGroupMenu(QMenu *menu, WebTab *tab)
{
    if (!menu || !tab || !m_window) {
        return;
    }

    TabWidget *tabWidget = m_window->tabWidget();
    TabGroupModel *groups = tabWidget->tabGroupModel();
    const QString currentGroup = tabWidget->tabGroupForTab(tab);
    const QPointer<WebTab> guardedTab(tab);

    QAction *noGroupAction = menu->addAction(tr("No Group"));
    noGroupAction->setData(QString());
    noGroupAction->setCheckable(true);
    noGroupAction->setChecked(currentGroup.isEmpty());
    connect(noGroupAction, &QAction::triggered, this, [this, guardedTab]() {
        moveTabToGroup(guardedTab, QString());
    });

    const QStringList groupIds = groups->groupIds();
    if (!groupIds.isEmpty()) {
        menu->addSeparator();
    }
    for (const QString &groupId : groupIds) {
        QAction *action = menu->addAction(groups->groupName(groupId));
        action->setData(groupId);
        action->setCheckable(true);
        action->setChecked(groupId == currentGroup);
        connect(action, &QAction::triggered, this, [this, guardedTab, groupId]() {
            moveTabToGroup(guardedTab, groupId);
        });
    }
}

void TabSearchPopup::populateGlobalGroupMenu(QMenu *menu)
{
    if (!menu) {
        return;
    }

    menu->clear();
    WebTab *tab = currentTab();
    if (!tab || !m_window) {
        menu->addAction(tr("New Tab Group"), this, [this, tab]() {
            createTabGroup(tab);
        });
        return;
    }

    populateGroupActions(menu, tab);
}

void TabSearchPopup::addTabStateRows(QMenu *menu, WebTab *tab) const
{
    if (!menu) {
        return;
    }

    const QStringList lines = stateSummary(tab);
    if (lines.isEmpty()) {
        return;
    }

    for (const QString &line : lines) {
        QAction *stateAction = menu->addAction(line);
        stateAction->setEnabled(false);
    }
    menu->addSeparator();
}

QStringList TabSearchPopup::stateSummary(WebTab *tab) const
{
    if (!tab || !m_window || !m_window->tabModel()) {
        return {};
    }

    const QModelIndex index = m_window->tabModel()->tabIndex(tab);
    if (!index.isValid()) {
        return {};
    }

    QStringList lines;
    const QString groupName = index.data(TabModel::TabGroupNameRole).toString().simplified();
    const QString owner = index.data(TabModel::TabOwnerRole).toString().simplified();
    const QString health = index.data(TabModel::TabHealthRole).toString().simplified();
    if (!groupName.isEmpty()) {
        lines.append(tr("Group: %1").arg(groupName));
    }
    if (!owner.isEmpty()) {
        lines.append(tr("Owner: %1").arg(owner));
    }
    if (index.data(TabModel::ActiveAutomationRole).toBool()) {
        lines.append(tr("Active automation"));
    }
    if (index.data(TabModel::SupervisionRole).toBool()) {
        lines.append(tr("Supervised session active"));
    }
    if (!health.isEmpty() && health.compare(QSL("ok"), Qt::CaseInsensitive) != 0) {
        lines.append(tr("Tab health: %1").arg(health));
    }
    return lines;
}
QStringList TabSearchPopup::stateSummary(const QVector<WebTab*> &tabs) const
{
    if (!m_window || !m_window->tabModel()) {
        return {};
    }

    QSet<QString> owners;
    QSet<QString> groups;
    QSet<QString> healthStates;
    int activeAutomationCount = 0;
    int supervisedCount = 0;
    for (WebTab *tab : tabs) {
        if (!tab) {
            continue;
        }
        const QModelIndex index = m_window->tabModel()->tabIndex(tab);
        if (!index.isValid()) {
            continue;
        }
        const QString groupName = index.data(TabModel::TabGroupNameRole).toString().simplified();
        const QString owner = index.data(TabModel::TabOwnerRole).toString().simplified();
        const QString health = index.data(TabModel::TabHealthRole).toString().simplified();
        if (!groupName.isEmpty()) {
            groups.insert(groupName);
        }
        if (!owner.isEmpty()) {
            owners.insert(owner);
        }
        if (index.data(TabModel::ActiveAutomationRole).toBool()) {
            ++activeAutomationCount;
        }
        if (index.data(TabModel::SupervisionRole).toBool()) {
            ++supervisedCount;
        }
        if (!health.isEmpty() && health.compare(QSL("ok"), Qt::CaseInsensitive) != 0) {
            healthStates.insert(health);
        }
    }

    QStringList groupList;
    for (const QString &group : groups) {
        groupList.append(group);
    }
    groupList.sort();

    QStringList ownerList;
    for (const QString &owner : owners) {
        ownerList.append(owner);
    }
    ownerList.sort();

    QStringList healthList;
    for (const QString &health : healthStates) {
        healthList.append(health);
    }
    healthList.sort();

    QStringList lines;
    if (!groupList.isEmpty()) {
        lines.append(tr("Groups: %1").arg(groupList.join(QSL(", "))));
    }
    if (!ownerList.isEmpty()) {
        lines.append(tr("Owned tabs: %1").arg(ownerList.join(QSL(", "))));
    }
    if (activeAutomationCount > 0) {
        lines.append(tr("Active automation tabs: %1").arg(activeAutomationCount));
    }
    if (supervisedCount > 0) {
        lines.append(tr("Supervised tabs: %1").arg(supervisedCount));
    }
    if (!healthList.isEmpty()) {
        lines.append(tr("Tab health: %1").arg(healthList.join(QSL(", "))));
    }
    return lines;
}

QString TabSearchPopup::createTabGroup(WebTab *tab)
{
    if (!m_window) {
        return {};
    }

    bool ok = false;
    const QString name = QInputDialog::getText(this,
                                               tr("New Tab Group"),
                                               tr("Group name:"),
                                               QLineEdit::Normal,
                                               tr("Tab Group"),
                                               &ok);
    if (!ok) {
        return {};
    }

    TabWidget *tabWidget = m_window->tabWidget();
    const QString groupId = tabWidget->createTabGroup(name, QString(), false);
    if (!groupId.isEmpty() && tab) {
        tabWidget->setTabGroup(tab, groupId);
    }
    populateGroupFilter();
    updateEmptyState();
    selectFirstVisibleRow();
    return groupId;
}

void TabSearchPopup::renameTabGroup(const QString &groupId)
{
    if (!m_window || groupId.isEmpty()) {
        return;
    }

    TabWidget *tabWidget = m_window->tabWidget();
    TabGroupModel *groups = tabWidget->tabGroupModel();
    bool ok = false;
    const QString name = QInputDialog::getText(this,
                                               tr("Rename Tab Group"),
                                               tr("Group name:"),
                                               QLineEdit::Normal,
                                               groups->groupName(groupId),
                                               &ok);
    if (ok) {
        tabWidget->renameTabGroup(groupId, name);
        populateGroupFilter();
    }
}

void TabSearchPopup::toggleTabGroupCollapsed(const QString &groupId)
{
    if (!m_window || groupId.isEmpty()) {
        return;
    }

    TabWidget *tabWidget = m_window->tabWidget();
    TabGroupModel *groups = tabWidget->tabGroupModel();
    tabWidget->setTabGroupCollapsed(groupId, !groups->isGroupCollapsed(groupId));
    populateGroupFilter();
    updateEmptyState();
    selectFirstVisibleRow();
}

void TabSearchPopup::moveTabToGroup(WebTab *tab, const QString &groupId)
{
    if (!tab || !m_window) {
        return;
    }
    m_window->tabWidget()->setTabGroup(tab, groupId);
    populateGroupFilter();
    updateEmptyState();
    selectFirstVisibleRow();
}

void TabSearchPopup::closeTabGroup(const QString &groupId)
{
    if (!m_window || groupId.isEmpty()) {
        return;
    }

    TabWidget *tabWidget = m_window->tabWidget();
    const QVector<WebTab*> tabs = tabWidget->tabsInGroup(groupId);
    if (confirmTabs(QSL("AskOnClosingTabGroup"),
                    tr("Close Tab Group"),
                    tr("Close all tabs in this group? This can be undone from Recently Closed Tabs."),
                    stateSummary(tabs))) {
        tabWidget->closeTabGroup(groupId);
        populateGroupFilter();
        updateEmptyState();
        selectFirstVisibleRow();
    }
}

bool TabSearchPopup::confirmTabs(const QString &settingsKey, const QString &title, const QString &description, const QStringList &stateLines) const
{
    Settings settings;
    const QString fullKey = QSL("Browser-Tabs-Settings/") + settingsKey;
    const bool ask = settings.value(fullKey, true).toBool();

    if (ask) {
        CheckBoxDialog dialog(QMessageBox::Yes | QMessageBox::No, m_window);
        dialog.setDefaultButton(QMessageBox::No);
        dialog.setWindowTitle(title);
        dialog.setText(stateLines.isEmpty() ? description : description + QSL("\n\n") + stateLines.join(QSL("\n")));
        dialog.setCheckBoxText(tr("Don't ask again"));
        dialog.setIcon(QMessageBox::Question);

        if (dialog.exec() != QMessageBox::Yes) {
            return false;
        }

        if (dialog.isChecked()) {
            settings.setValue(fullKey, false);
        }
    }

    return true;
}
