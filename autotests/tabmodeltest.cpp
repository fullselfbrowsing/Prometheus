/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2018 David Rosca <nowrep@gmail.com>
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
#include "tabmodeltest.h"
#include "autotests.h"
#include "tabgroupmodel.h"
#include "tabmodel.h"
#include "tabtreemodel.h"
#include "tabmrumodel.h"
#include "webtab.h"
#include "tabwidget.h"
#include "mainapplication.h"
#include "browserwindow.h"

#include "modeltest.h"

void TabModelTest::initTestCase()
{
}

void TabModelTest::cleanupTestCase()
{
}

void TabModelTest::basicTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    TabModel model1(w);
    ModelTest modelTest(&model1);

    QSignalSpy rowsInsertedSpy(&model1, &TabModel::rowsInserted);
    QSignalSpy rowsRemovedSpy(&model1, &TabModel::rowsRemoved);

    QCOMPARE(model1.rowCount(), 0);

    rowsInsertedSpy.wait();

    QCOMPARE(rowsInsertedSpy.count(), 1);
    WebTab *tab0 = w->tabWidget()->webTab(0);
    QCOMPARE(rowsInsertedSpy.at(0).at(0).value<QModelIndex>(), QModelIndex());
    QCOMPARE(rowsInsertedSpy.at(0).at(1).toInt(), 0);
    QCOMPARE(rowsInsertedSpy.at(0).at(2).toInt(), 0);
    QCOMPARE(model1.data(model1.index(0, 0), TabModel::WebTabRole).value<WebTab*>(), tab0);

    rowsInsertedSpy.clear();

    w->tabWidget()->addView(QUrl(QSL("http://test.com")));

    QCOMPARE(rowsInsertedSpy.count(), 1);
    WebTab *tab1 = w->tabWidget()->webTab(1);
    QCOMPARE(rowsInsertedSpy.at(0).at(0).value<QModelIndex>(), QModelIndex());
    QCOMPARE(rowsInsertedSpy.at(0).at(1).toInt(), 1);
    QCOMPARE(rowsInsertedSpy.at(0).at(2).toInt(), 1);
    QCOMPARE(model1.data(model1.index(1, 0), TabModel::WebTabRole).value<WebTab*>(), tab1);

    w->tabWidget()->moveTab(0, 1);
    QCOMPARE(w->tabWidget()->webTab(0), tab1);
    QCOMPARE(w->tabWidget()->webTab(1), tab0);

    w->tabWidget()->moveTab(1, 0);
    QCOMPARE(w->tabWidget()->webTab(0), tab0);
    QCOMPARE(w->tabWidget()->webTab(1), tab1);

    w->tabWidget()->moveTab(0, 1);
    QCOMPARE(w->tabWidget()->webTab(0), tab1);
    QCOMPARE(w->tabWidget()->webTab(1), tab0);

    QCOMPARE(rowsRemovedSpy.count(), 0);

    w->tabWidget()->closeTab(1);

    QCOMPARE(rowsRemovedSpy.count(), 1);
    QCOMPARE(rowsRemovedSpy.at(0).at(0).value<QModelIndex>(), QModelIndex());
    QCOMPARE(rowsRemovedSpy.at(0).at(1).toInt(), 1);
    QCOMPARE(rowsRemovedSpy.at(0).at(2).toInt(), 1);

    QCOMPARE(model1.rowCount(), 1);

    TabModel model2(w);
    ModelTest modelTest2(&model2);
    QCOMPARE(model2.rowCount(), 1);

    delete w;
}

void TabModelTest::dataTest()
{
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
    QCOMPARE(model.index(0, 0).data(TabModel::TabOwnerRole).toString(), QString());
    QCOMPARE(model.index(0, 0).data(TabModel::ActiveAutomationRole).toBool(), false);
    QCOMPARE(model.index(0, 0).data(TabModel::SupervisionRole).toBool(), false);
    QCOMPARE(model.index(0, 0).data(TabModel::TabHealthRole).toString(), QSL("ok"));

    w->tabWidget()->addView(QUrl(QSL("http://test.com")));

    delete w;
}

void TabModelTest::tabGroupRoleDefaultsTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);
    TabModel model(w);
    ModelTest modelTest(&model);

    QTRY_COMPARE(model.rowCount(), 1);

    const QModelIndex firstTab = model.index(0, 0);
    QCOMPARE(firstTab.data(TabModel::TabGroupIdRole).toString(), QString());
    QCOMPARE(firstTab.data(TabModel::TabGroupNameRole).toString(), QString());
    QCOMPARE(firstTab.data(TabModel::TabGroupColorRole).toString(), QString());
    QCOMPARE(firstTab.data(TabModel::TabGroupCollapsedRole).toBool(), false);

    delete w;
}

void TabModelTest::tabGroupRoleMetadataTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);
    TabModel model(w);
    TabGroupModel groups;
    model.setTabGroupModel(&groups);
    ModelTest modelTest(&model);

    QTRY_COMPARE(model.rowCount(), 1);

    WebTab *tab = w->tabWidget()->webTab(0);
    const QString groupId = groups.createGroup(QSL("Research"), QSL("#3a7bd5"));
    QVERIFY(!groupId.isEmpty());

    QSignalSpy dataChangedSpy(&model, &TabModel::dataChanged);
    QVERIFY(groups.setTabGroup(tab, groupId));

    const QModelIndex firstTab = model.index(0, 0);
    QCOMPARE(firstTab.data(TabModel::TabGroupIdRole).toString(), groupId);
    QCOMPARE(firstTab.data(TabModel::TabGroupNameRole).toString(), QSL("Research"));
    QCOMPARE(firstTab.data(TabModel::TabGroupColorRole).toString(), QSL("#3a7bd5"));
    QCOMPARE(firstTab.data(TabModel::TabGroupCollapsedRole).toBool(), false);
    QVERIFY(!dataChangedSpy.isEmpty());

    dataChangedSpy.clear();
    QVERIFY(groups.renameGroup(groupId, QSL("Work Queue")));
    QVERIFY(groups.setGroupColor(groupId, QSL("#2f9e7e")));
    QVERIFY(groups.setGroupCollapsed(groupId, true));

    QCOMPARE(firstTab.data(TabModel::TabGroupNameRole).toString(), QSL("Work Queue"));
    QCOMPARE(firstTab.data(TabModel::TabGroupColorRole).toString(), QSL("#2f9e7e"));
    QCOMPARE(firstTab.data(TabModel::TabGroupCollapsedRole).toBool(), true);
    QVERIFY(!dataChangedSpy.isEmpty());

    delete w;
}

void TabModelTest::tabGroupRoleMovePreservesMembershipTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);
    TabModel model(w);
    TabGroupModel groups;
    model.setTabGroupModel(&groups);
    ModelTest modelTest(&model);

    w->tabWidget()->addView(QUrl(QSL("http://test.com")));
    QTRY_COMPARE(model.rowCount(), 2);

    WebTab *tab0 = w->tabWidget()->webTab(0);
    WebTab *tab1 = w->tabWidget()->webTab(1);
    const QString groupId = groups.createGroup(QSL("Research"), QSL("#3a7bd5"));
    QVERIFY(groups.setTabGroup(tab0, groupId));

    w->tabWidget()->moveTab(0, 1);

    QCOMPARE(w->tabWidget()->webTab(0), tab1);
    QCOMPARE(w->tabWidget()->webTab(1), tab0);
    QCOMPARE(model.index(0, 0).data(TabModel::TabGroupIdRole).toString(), QString());
    QCOMPARE(model.index(1, 0).data(TabModel::TabGroupIdRole).toString(), groupId);
    QCOMPARE(model.index(1, 0).data(TabModel::TabGroupNameRole).toString(), QSL("Research"));
    QCOMPARE(model.index(1, 0).data(TabModel::TabGroupColorRole).toString(), QSL("#3a7bd5"));

    delete w;
}

void TabModelTest::tabWidgetGroupOperationsTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    QTRY_COMPARE(w->tabModel()->rowCount(), 1);

    WebTab *tab = w->tabWidget()->webTab(0);
    const QString groupId = w->tabWidget()->createTabGroup(QSL("Research"), QSL("#3a7bd5"));
    QVERIFY(!groupId.isEmpty());
    QVERIFY(w->tabWidget()->setTabGroup(tab, groupId));

    QCOMPARE(tab->sessionData().value(QSL("prometheusTabGroupId")).toString(), groupId);
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupIdRole).toString(), groupId);
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupNameRole).toString(), QSL("Research"));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupColorRole).toString(), QSL("#3a7bd5"));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupCollapsedRole).toBool(), false);

    QVERIFY(w->tabWidget()->renameTabGroup(groupId, QSL("Focus Queue")));
    QVERIFY(w->tabWidget()->setTabGroupColor(groupId, QSL("#2f9e7e")));
    QVERIFY(w->tabWidget()->setTabGroupCollapsed(groupId, true));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupNameRole).toString(), QSL("Focus Queue"));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupColorRole).toString(), QSL("#2f9e7e"));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupCollapsedRole).toBool(), true);

    QVERIFY(w->tabWidget()->setTabGroupColor(groupId, QSL("#ff6b35")));
    QCOMPARE(w->tabModel()->index(0, 0).data(TabModel::TabGroupColorRole).toString(), QSL("#3a7bd5"));

    delete w;
}

void TabModelTest::tabWidgetGroupDuplicateAndRestoreTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    int groupedIndex = w->tabWidget()->addView(QUrl(QSL("http://grouped.test")), Qz::NT_SelectedTab);
    QTRY_COMPARE(w->tabModel()->rowCount(), 2);

    WebTab *groupedTab = w->tabWidget()->webTab(groupedIndex);
    const QString groupId = w->tabWidget()->createTabGroup(QSL("Research"), QSL("#3a7bd5"));
    QVERIFY(w->tabWidget()->setTabGroup(groupedTab, groupId));

    const int duplicateIndex = w->tabWidget()->duplicateTab(groupedIndex);
    QVERIFY(duplicateIndex >= 0);
    QCOMPARE(w->tabWidget()->webTab(duplicateIndex)->sessionData().value(QSL("prometheusTabGroupId")).toString(), groupId);
    QCOMPARE(w->tabModel()->index(duplicateIndex, 0).data(TabModel::TabGroupIdRole).toString(), groupId);

    w->tabWidget()->closeTab(duplicateIndex);
    QVERIFY(w->tabWidget()->canRestoreTab());
    w->tabWidget()->restoreClosedTab();

    bool restoredGroupedTabFound = false;
    for (int i = 0; i < w->tabWidget()->count(); ++i) {
        WebTab *tab = w->tabWidget()->webTab(i);
        if (tab->sessionData().value(QSL("prometheusTabGroupId")).toString() == groupId) {
            restoredGroupedTabFound = true;
            QCOMPARE(w->tabModel()->index(i, 0).data(TabModel::TabGroupIdRole).toString(), groupId);
        }
    }
    QVERIFY(restoredGroupedTabFound);

    delete w;
}

void TabModelTest::tabWidgetGroupSessionRestoreTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    const int groupedIndex = w->tabWidget()->addView(QUrl(QSL("http://session-group.test")), Qz::NT_SelectedTab);
    QTRY_COMPARE(w->tabModel()->rowCount(), 2);

    const QString groupId = w->tabWidget()->createTabGroup(QSL("Session Group"), QSL("#9b6ade"));
    QVERIFY(w->tabWidget()->setTabGroup(w->tabWidget()->webTab(groupedIndex), groupId));
    QVERIFY(w->tabWidget()->setTabGroupCollapsed(groupId, true));

    BrowserWindow::SavedWindow savedWindow(w);
    QVERIFY(savedWindow.windowUiState.contains(QSL("TabGroups")));

    bool savedMembershipFound = false;
    for (const WebTab::SavedTab &tab : std::as_const(savedWindow.tabs)) {
        if (tab.sessionData.value(QSL("prometheusTabGroupId")).toString() == groupId) {
            savedMembershipFound = true;
        }
    }
    QVERIFY(savedMembershipFound);

    BrowserWindow *restored = mApp->createWindow(Qz::BW_OtherRestoredWindow);
    restored->restoreWindow(savedWindow);
    QTRY_VERIFY(restored->tabWidget()->tabGroupModel()->containsGroup(groupId));

    QCOMPARE(restored->tabWidget()->tabGroupModel()->groupName(groupId), QSL("Session Group"));
    QCOMPARE(restored->tabWidget()->tabGroupModel()->groupColor(groupId), QSL("#9b6ade"));
    QCOMPARE(restored->tabWidget()->tabGroupModel()->isGroupCollapsed(groupId), true);

    bool restoredMembershipFound = false;
    for (int i = 0; i < restored->tabWidget()->count(); ++i) {
        if (restored->tabModel()->index(i, 0).data(TabModel::TabGroupIdRole).toString() == groupId) {
            restoredMembershipFound = true;
        }
    }
    QVERIFY(restoredMembershipFound);

    delete restored;
    delete w;
}

void TabModelTest::pinTabTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    TabModel model(w);
    ModelTest modelTest(&model);

    w->tabWidget()->addView(QUrl(QSL("http://test.com")));

    QTRY_COMPARE(model.rowCount(), 2);

    WebTab *tab0 = w->tabWidget()->webTab(0);
    WebTab *tab1 = w->tabWidget()->webTab(1);

    QCOMPARE(model.data(model.index(0, 0), TabModel::WebTabRole).value<WebTab*>(), tab0);
    QCOMPARE(model.data(model.index(1, 0), TabModel::WebTabRole).value<WebTab*>(), tab1);

    tab1->togglePinned();

    QCOMPARE(model.data(model.index(0, 0), TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.data(model.index(1, 0), TabModel::WebTabRole).value<WebTab*>(), tab0);

    delete w;
}

void TabModelTest::treeModelTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    TabModel sourceModel(w);
    TabTreeModel model(w);
    model.setSourceModel(&sourceModel);
    ModelTest modelTest(&model);

    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());

    QTRY_COMPARE(model.rowCount(QModelIndex()), 6);

    WebTab *tab1 = w->tabWidget()->webTab(0);
    WebTab *tab2 = w->tabWidget()->webTab(1);
    WebTab *tab3 = w->tabWidget()->webTab(2);
    WebTab *tab4 = w->tabWidget()->webTab(3);
    WebTab *tab5 = w->tabWidget()->webTab(4);
    WebTab *tab6 = w->tabWidget()->webTab(5);

    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(4, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(5, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab6);

    QPersistentModelIndex tab1index = model.index(0, 0);
    QPersistentModelIndex tab2index = model.index(1, 0);
    QPersistentModelIndex tab3index = model.index(2, 0);
    QPersistentModelIndex tab4index = model.index(3, 0);
    QPersistentModelIndex tab5index = model.index(4, 0);
    QPersistentModelIndex tab6index = model.index(5, 0);

    QCOMPARE(model.rowCount(tab1index), 0);
    tab1->addChildTab(tab2);

    QCOMPARE(model.rowCount(tab1index), 1);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab2);

    tab1->addChildTab(tab3);
    QCOMPARE(model.rowCount(tab1index), 2);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(1, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab3);

    tab1->addChildTab(tab4, 1);
    QCOMPARE(model.rowCount(tab1index), 3);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(1, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(2, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab3);

    tab4->addChildTab(tab5);
    tab4->addChildTab(tab6);

    QCOMPARE(model.rowCount(tab4index), 2);
    QCOMPARE(model.index(0, 0, tab4index).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(1, 0, tab4index).data(TabModel::WebTabRole).value<WebTab*>(), tab6);

    w->tabWidget()->closeTab(tab4->tabIndex());

    QCOMPARE(model.rowCount(tab1index), 4);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(1, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(2, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab6);
    QCOMPARE(model.index(3, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab3);

    tab1->addChildTab(tab3, 0);

    QCOMPARE(model.rowCount(tab1index), 4);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(1, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(2, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(3, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab6);

    tab2->setParentTab(nullptr);

    QCOMPARE(model.rowCount(tab1index), 3);
    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(0, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(1, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(2, 0, tab1index).data(TabModel::WebTabRole).value<WebTab*>(), tab6);

    w->tabWidget()->closeTab(tab1->tabIndex());

    QCOMPARE(model.rowCount(QModelIndex()), 4);
    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab6);

    delete w;
}

void TabModelTest::resetTreeModelTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    TabModel sourceModel(w);
    TabTreeModel model(w);
    model.setSourceModel(&sourceModel);
    ModelTest modelTest(&model);

    QTRY_COMPARE(model.rowCount(QModelIndex()), 1);

    delete w;

    QCOMPARE(model.rowCount(QModelIndex()), 0);
}
void TabModelTest::mruModelTest()
{
    BrowserWindow *w = mApp->createWindow(Qz::BW_NewWindow);

    TabModel sourceModel(w);
    TabMruModel model(w);
    model.setSourceModel(&sourceModel);
    ModelTest modelTest(&model);

    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());
    w->tabWidget()->addView(QUrl());

    QTRY_COMPARE(model.rowCount(QModelIndex()), 6);

    WebTab *tab0 = w->tabWidget()->webTab(0);
    WebTab *tab1 = w->tabWidget()->webTab(1);
    WebTab *tab2 = w->tabWidget()->webTab(2);
    WebTab *tab3 = w->tabWidget()->webTab(3);
    WebTab *tab4 = w->tabWidget()->webTab(4);
    WebTab *tab5 = w->tabWidget()->webTab(5);

    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab0);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(4, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(5, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);

    w->tabWidget()->setCurrentIndex(2);
    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab0);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(4, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(5, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    w->tabWidget()->setCurrentIndex(2);

    w->tabWidget()->setCurrentIndex(4);
    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab0);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.index(4, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);
    QCOMPARE(model.index(5, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);

    w->tabWidget()->setCurrentIndex(5);
    QCOMPARE(model.index(0, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab5);
    QCOMPARE(model.index(1, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab4);
    QCOMPARE(model.index(2, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab2);
    QCOMPARE(model.index(3, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab0);
    QCOMPARE(model.index(4, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab1);
    QCOMPARE(model.index(5, 0).data(TabModel::WebTabRole).value<WebTab*>(), tab3);

    delete w;
}

FALKONTEST_MAIN(TabModelTest)
