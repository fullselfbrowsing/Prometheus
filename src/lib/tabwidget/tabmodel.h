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
#pragma once

#include <QPointer>
#include <QMimeData>
#include <QAbstractListModel>

#include "qzcommon.h"

class WebTab;
class BrowserWindow;
class TabGroupModel;

class FALKON_EXPORT TabModelMimeData : public QMimeData
{
    Q_OBJECT

public:
    explicit TabModelMimeData();

    WebTab *tab() const;
    void setTab(WebTab *tab);

    bool hasFormat(const QString &format) const override;
    QStringList formats() const override;

    static QString mimeType();

private:
    QPointer<WebTab> m_tab;
};

class FALKON_EXPORT TabModel : public QAbstractListModel
{
    Q_OBJECT

public:
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
        BackgroundActivityRole = Qt::UserRole + 10,
        TabOwnerRole = Qt::UserRole + 11,
        ActiveAutomationRole = Qt::UserRole + 12,
        SupervisionRole = Qt::UserRole + 13,
        TabHealthRole = Qt::UserRole + 14,
        TabGroupIdRole = Qt::UserRole + 15,
        TabGroupNameRole = Qt::UserRole + 16,
        TabGroupColorRole = Qt::UserRole + 17,
        TabGroupCollapsedRole = Qt::UserRole + 18
    };

    explicit TabModel(BrowserWindow *window, QObject *parent = nullptr);

    QModelIndex tabIndex(WebTab *tab) const;
    WebTab *tab(const QModelIndex &index) const;
    TabGroupModel *tabGroupModel() const;
    void setTabGroupModel(TabGroupModel *model);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    Qt::DropActions supportedDropActions() const override;
    QStringList mimeTypes() const override;
    QMimeData *mimeData(const QModelIndexList &indexes) const override;
    bool canDropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent) const override;
    bool dropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent) override;

private:
    void init();
    void tabInserted(int index);
    void tabRemoved(int index);
    void tabMoved(int from, int to);
    void tabChromeStateChanged(int windowIndex, int tabIndex);
    void tabGroupChanged(WebTab *tab);
    void tabGroupMetadataChanged(const QString &groupId);

    BrowserWindow *m_window;
    QPointer<TabGroupModel> m_tabGroupModel;
    QVector<WebTab*> m_tabs;
};
