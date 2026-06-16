/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2010-2018 David Rosca <nowrep@gmail.com>
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
#include "tabcontextmenu.h"
#include "tabbar.h"
#include "tabwidget.h"
#include "browserwindow.h"
#include "webtab.h"
#include "settings.h"
#include "tabbedwebview.h"
#include "mainapplication.h"
#include "iconprovider.h"
#include "checkboxdialog.h"
#include "tabgroupmodel.h"
#include "tabmodel.h"

#include <QAction>
#include <QInputDialog>
#include <QLineEdit>
#include <QSet>

TabContextMenu::TabContextMenu(int index, BrowserWindow *window, Options options)
    : QMenu()
    , m_clickedTab(index)
    , m_window(window)
    , m_options(options)
{
    setObjectName(QStringLiteral("tabcontextmenu"));

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

    init();
}

static bool canCloseTabs(const QString &settingsKey, const QString &title, const QString &description, QWidget *parent, const QStringList &stateLines = {})
{
    Settings settings;
    bool ask = settings.value(QSL("Browser-Tabs-Settings/") + settingsKey, true).toBool();

    if (ask) {
        CheckBoxDialog dialog(QMessageBox::Yes | QMessageBox::No, parent ? parent : mApp->activeWindow());
        dialog.setDefaultButton(QMessageBox::No);
        dialog.setWindowTitle(title);
        dialog.setText(stateLines.isEmpty() ? description : description + QSL("\n\n") + stateLines.join(QSL("\n")));
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
}

void TabContextMenu::closeAllButCurrent()
{
    QVector<WebTab*> affectedTabs;
    TabWidget *tabWidget = m_window->tabWidget();
    const auto tabs = tabWidget->allTabs(false);
    for (WebTab *tab : tabs) {
        if (tab && tab->tabIndex() != m_clickedTab) {
            affectedTabs.append(tab);
        }
    }

    if (confirmTabs(QLatin1String("AskOnClosingAllButCurrent"),
                    tr("Close Other Tabs"),
                    tr("Close all other tabs?"),
                    stateSummary(affectedTabs))) {
        Q_EMIT closeAllButCurrent(m_clickedTab);
    }
}

void TabContextMenu::closeToRight()
{
    QVector<WebTab*> affectedTabs;
    TabWidget *tabWidget = m_window->tabWidget();
    const auto tabs = tabWidget->allTabs(false);
    for (WebTab *tab : tabs) {
        if (tab && tab->tabIndex() > m_clickedTab) {
            affectedTabs.append(tab);
        }
    }

    const QString title = m_options & HorizontalTabs ? tr("Close Tabs to the Right") : tr("Close Tabs to the Bottom");
    if (confirmTabs(QLatin1String("AskOnClosingToRight"), title, tr("Close these tabs?"), stateSummary(affectedTabs))) {
        Q_EMIT closeToRight(m_clickedTab);
    }
}

void TabContextMenu::closeToLeft()
{
    QVector<WebTab*> affectedTabs;
    TabWidget *tabWidget = m_window->tabWidget();
    const auto tabs = tabWidget->allTabs(false);
    for (WebTab *tab : tabs) {
        if (tab && tab->tabIndex() < m_clickedTab) {
            affectedTabs.append(tab);
        }
    }

    const QString title = m_options & HorizontalTabs ? tr("Close Tabs to the Left") : tr("Close Tabs to the Top");
    if (confirmTabs(QLatin1String("AskOnClosingToLeft"), title, tr("Close these tabs?"), stateSummary(affectedTabs))) {
        Q_EMIT closeToLeft(m_clickedTab);
    }
}

void TabContextMenu::init()
{
    TabWidget *tabWidget = m_window->tabWidget();
    if (m_clickedTab != -1) {
        WebTab* webTab = tabWidget->webTab(m_clickedTab);
        if (!webTab) {
            return;
        }

        if (m_window->weView(m_clickedTab)->isLoading()) {
            addAction(QIcon::fromTheme(QSL("process-stop")), tr("&Stop Tab"), this, SLOT(stopTab()));
        }
        else {
            addAction(QIcon::fromTheme(QSL("view-refresh")), tr("&Reload Tab"), this, SLOT(reloadTab()));
        }

        addTabStateRows(webTab);
        addAction(QIcon::fromTheme(QSL("tab-duplicate")), tr("&Duplicate Tab"), this, SLOT(duplicateTab()));

        if (m_options & ShowDetachTabAction && (mApp->windowCount() > 1 || tabWidget->count() > 1)) {
            addAction(QIcon::fromTheme(QSL("tab-detach")), tr("D&etach Tab"), this, SLOT(detachTab()));
        }

        addAction(webTab->isPinned() ? tr("Un&pin Tab") : tr("&Pin Tab"), this, &TabContextMenu::pinTab);
        addAction(webTab->isMuted() ? tr("Un&mute Tab") : tr("&Mute Tab"), this, &TabContextMenu::muteTab);

        if (!webTab->isRestored()) {
            addAction(tr("Load Tab"), this, SLOT(loadTab()));
        } else {
            addAction(tr("Unload Tab"), this, SLOT(unloadTab()));
        }

        QMenu *tabGroupMenu = addMenu(tr("Tab Group"));
        populateTabGroupMenu(tabGroupMenu, webTab);

        addSeparator();
        addAction(tr("Re&load All Tabs"), tabWidget, &TabWidget::reloadAllTabs);
        addAction(tr("Bookmark &All Tabs"), m_window, &BrowserWindow::bookmarkAllTabs);
        addSeparator();

        if (m_options & ShowCloseOtherTabsActions) {
            addAction(tr("Close Ot&her Tabs"), this, SLOT(closeAllButCurrent()));
            addAction(m_options & HorizontalTabs ? tr("Close Tabs To The Right") : tr("Close Tabs To The Bottom"), this, SLOT(closeToRight()));
            addAction(m_options & HorizontalTabs ? tr("Close Tabs To The Left") : tr("Close Tabs To The Top"), this, SLOT(closeToLeft()));
            addSeparator();
        }

        addAction(m_window->action(QSL("Other/RestoreClosedTab")));
        if (tabWidget->canRestoreTab()) {
            addAction(QIcon::fromTheme(QSL("edit-clear")), tr("Clear Closed Tabs"), this, &TabContextMenu::requestClearClosedTabsList);
        }
        addAction(QIcon::fromTheme(QSL("window-close")), tr("Cl&ose Tab"), this, &TabContextMenu::closeTab);
    } else {
        addAction(IconProvider::newTabIcon(), tr("&New tab"), m_window, &BrowserWindow::addTab);
        addAction(tr("New Tab Group"), this, &TabContextMenu::newTabGroup);
        addSeparator();
        addAction(tr("Reloa&d All Tabs"), tabWidget, &TabWidget::reloadAllTabs);
        addAction(tr("Bookmark &All Tabs"), m_window, &BrowserWindow::bookmarkAllTabs);
        addSeparator();
        addAction(m_window->action(QSL("Other/RestoreClosedTab")));
        if (tabWidget->canRestoreTab()) {
            addAction(QIcon::fromTheme(QSL("edit-clear")), tr("Clear Closed Tabs"), this, &TabContextMenu::requestClearClosedTabsList);
        }
    }

    m_window->action(QSL("Other/RestoreClosedTab"))->setEnabled(tabWidget->canRestoreTab());
    connect(this, &QMenu::aboutToHide, this, [this]() {
        m_window->action(QSL("Other/RestoreClosedTab"))->setEnabled(true);
    });
}

void TabContextMenu::pinTab()
{
    WebTab* webTab = m_window->tabWidget()->webTab(m_clickedTab);
    if (webTab) {
        webTab->togglePinned();
    }
}

void TabContextMenu::muteTab()
{
    WebTab* webTab = m_window->tabWidget()->webTab(m_clickedTab);
    if (webTab) {
        webTab->toggleMuted();
    }
}

void TabContextMenu::newTabGroup()
{
    TabWidget *tabWidget = m_window->tabWidget();
    bool ok = false;
    const QString name = QInputDialog::getText(m_window,
                                               tr("New Tab Group"),
                                               tr("Group name:"),
                                               QLineEdit::Normal,
                                               tr("Tab Group"),
                                               &ok);
    if (!ok) {
        return;
    }

    const QString groupId = tabWidget->createTabGroup(name, QString(), false);
    if (groupId.isEmpty()) {
        return;
    }

    if (m_clickedTab >= 0) {
        tabWidget->setTabGroup(m_clickedTab, groupId);
    }
}

void TabContextMenu::renameTabGroup()
{
    const QString groupId = currentGroupId();
    if (groupId.isEmpty()) {
        return;
    }

    TabGroupModel *groups = m_window->tabWidget()->tabGroupModel();
    bool ok = false;
    const QString name = QInputDialog::getText(m_window,
                                               tr("Rename Tab Group"),
                                               tr("Group name:"),
                                               QLineEdit::Normal,
                                               groups->groupName(groupId),
                                               &ok);
    if (ok) {
        m_window->tabWidget()->renameTabGroup(groupId, name);
    }
}

void TabContextMenu::toggleTabGroupCollapsed()
{
    const QString groupId = currentGroupId();
    if (groupId.isEmpty()) {
        return;
    }

    TabGroupModel *groups = m_window->tabWidget()->tabGroupModel();
    m_window->tabWidget()->setTabGroupCollapsed(groupId, !groups->isGroupCollapsed(groupId));
}

void TabContextMenu::moveTabToGroup()
{
    if (m_clickedTab < 0) {
        return;
    }

    auto *action = qobject_cast<QAction*>(sender());
    if (!action) {
        return;
    }

    m_window->tabWidget()->setTabGroup(m_clickedTab, action->data().toString());
}

void TabContextMenu::closeTabGroup()
{
    const QString groupId = currentGroupId();
    if (groupId.isEmpty()) {
        return;
    }

    const QVector<WebTab*> tabs = m_window->tabWidget()->tabsInGroup(groupId);
    if (confirmTabs(QLatin1String("AskOnClosingTabGroup"),
                    tr("Close Tab Group"),
                    tr("Close all tabs in this group? This can be undone from Recently Closed Tabs."),
                    stateSummary(tabs))) {
        m_window->tabWidget()->closeTabGroup(groupId);
    }
}

void TabContextMenu::requestClearClosedTabsList()
{
    m_window->tabWidget()->requestClearClosedTabsList();
}

void TabContextMenu::addTabStateRows(WebTab *tab)
{
    const QStringList lines = stateSummary(tab);
    if (lines.isEmpty()) {
        return;
    }

    for (const QString &line : lines) {
        QAction *stateAction = addAction(line);
        stateAction->setEnabled(false);
    }
    addSeparator();
}

void TabContextMenu::populateTabGroupMenu(QMenu *menu, WebTab *tab)
{
    if (!menu || !tab) {
        return;
    }

    menu->addAction(tr("New Tab Group"), this, &TabContextMenu::newTabGroup);

    QMenu *moveMenu = menu->addMenu(tr("Move Tab to Group"));
    populateMoveToGroupMenu(moveMenu, tab);

    const QString groupId = m_window->tabWidget()->tabGroupForTab(tab);
    if (groupId.isEmpty()) {
        return;
    }

    TabGroupModel *groups = m_window->tabWidget()->tabGroupModel();
    menu->addSeparator();
    menu->addAction(tr("Rename Tab Group"), this, &TabContextMenu::renameTabGroup);
    menu->addAction(groups->isGroupCollapsed(groupId) ? tr("Expand Tab Group") : tr("Collapse Tab Group"),
                    this,
                    &TabContextMenu::toggleTabGroupCollapsed);
    menu->addAction(QIcon::fromTheme(QSL("window-close")), tr("Close Tab Group"), this, &TabContextMenu::closeTabGroup);
}

void TabContextMenu::populateMoveToGroupMenu(QMenu *menu, WebTab *tab)
{
    if (!menu || !tab) {
        return;
    }

    TabWidget *tabWidget = m_window->tabWidget();
    TabGroupModel *groups = tabWidget->tabGroupModel();
    const QString current = tabWidget->tabGroupForTab(tab);

    QAction *noGroupAction = menu->addAction(tr("No Group"), this, &TabContextMenu::moveTabToGroup);
    noGroupAction->setData(QString());
    noGroupAction->setCheckable(true);
    noGroupAction->setChecked(current.isEmpty());

    const QStringList groupIds = groups->groupIds();
    if (!groupIds.isEmpty()) {
        menu->addSeparator();
    }
    for (const QString &groupId : groupIds) {
        QAction *action = menu->addAction(groups->groupName(groupId), this, &TabContextMenu::moveTabToGroup);
        action->setData(groupId);
        action->setCheckable(true);
        action->setChecked(groupId == current);
    }
}

QString TabContextMenu::currentGroupId() const
{
    WebTab *tab = m_window->tabWidget()->webTab(m_clickedTab);
    return tab ? m_window->tabWidget()->tabGroupForTab(tab) : QString();
}

QStringList TabContextMenu::stateSummary(WebTab *tab) const
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

QStringList TabContextMenu::stateSummary(const QVector<WebTab*> &tabs) const
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

bool TabContextMenu::confirmTabs(const QString &settingsKey, const QString &title, const QString &description, const QStringList &stateLines) const
{
    return canCloseTabs(settingsKey, title, description, m_window, stateLines);
}
