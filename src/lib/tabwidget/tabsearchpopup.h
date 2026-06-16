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
#pragma once

#include "qzcommon.h"

#include <QFrame>
#include <QVector>

class BrowserWindow;
class QCheckBox;
class QComboBox;
class QLabel;
class QLineEdit;
class QListView;
class QMenu;
class QStackedWidget;
class QToolButton;
class TabSearchDelegate;
class TabSearchFilterModel;
class WebTab;

class FALKON_EXPORT TabSearchPopup : public QFrame
{
    Q_OBJECT

public:
    enum Mode {
        OverviewMode,
        SearchMode,
        QuickSwitchMode
    };
    Q_ENUM(Mode)

    explicit TabSearchPopup(BrowserWindow *window, QWidget *parent = nullptr);

    Mode mode() const;
    void setMode(Mode mode);

    void setGroupFilters(const QStringList &groups);

public Q_SLOTS:
    void showOverview();
    void showSearch();
    void showQuickSwitch();
    void popup(const QPoint &globalPosition);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;
    void showEvent(QShowEvent *event) override;

private:
    void updateSourceModel();
    void populateGroupFilter();
    void updateGroupFilterVisibility();
    void updateEmptyState();
    void selectFirstVisibleRow();
    void activateCurrentIndex();
    void routeNavigationKey(QKeyEvent *event);
    WebTab *currentTab() const;
    void showRowMenu(const QPoint &position);
    void populateTabActions(QMenu *menu, WebTab *tab);
    void populateGroupActions(QMenu *menu, WebTab *tab);
    void populateMoveToGroupMenu(QMenu *menu, WebTab *tab);
    void populateGlobalGroupMenu(QMenu *menu);
    void addTabStateRows(QMenu *menu, WebTab *tab) const;
    QStringList stateSummary(WebTab *tab) const;
    QStringList stateSummary(const QVector<WebTab*> &tabs) const;
    QString createTabGroup(WebTab *tab);
    void renameTabGroup(const QString &groupId);
    void toggleTabGroupCollapsed(const QString &groupId);
    void moveTabToGroup(WebTab *tab, const QString &groupId);
    void closeTabGroup(const QString &groupId);
    bool confirmTabs(const QString &settingsKey, const QString &title, const QString &description, const QStringList &stateLines = {}) const;

    BrowserWindow *m_window = nullptr;
    Mode m_mode = OverviewMode;
    TabSearchFilterModel *m_filterModel = nullptr;
    TabSearchDelegate *m_delegate = nullptr;
    QLineEdit *m_searchEdit = nullptr;
    QCheckBox *m_mruOrder = nullptr;
    QComboBox *m_groupFilter = nullptr;
    QToolButton *m_groupActions = nullptr;
    QListView *m_view = nullptr;
    QLabel *m_titleLabel = nullptr;
    QLabel *m_emptyTitle = nullptr;
    QLabel *m_emptyBody = nullptr;
    QStackedWidget *m_stack = nullptr;
};
