/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2026 Prometheus contributors
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

#include <QAbstractListModel>
#include <QHash>
#include <QPointer>

#include "qzcommon.h"

class WebTab;

class FALKON_EXPORT TabGroupModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole = Qt::UserRole + 2,
        ColorRole = Qt::UserRole + 3,
        CollapsedRole = Qt::UserRole + 4,
        MemberCountRole = Qt::UserRole + 5
    };

    explicit TabGroupModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString createGroup(const QString &name, const QString &color, bool collapsed = false);
    bool addGroup(const QString &id, const QString &name, const QString &color, bool collapsed = false);
    bool removeGroup(const QString &id);
    bool containsGroup(const QString &id) const;
    QStringList groupIds() const;

    QString groupName(const QString &id) const;
    QString groupColor(const QString &id) const;
    bool isGroupCollapsed(const QString &id) const;

    bool renameGroup(const QString &id, const QString &name);
    bool setGroupColor(const QString &id, const QString &color);
    bool setGroupCollapsed(const QString &id, bool collapsed);

    QString tabGroupId(WebTab *tab) const;
    bool setTabGroup(WebTab *tab, const QString &groupId);
    bool clearTabGroup(WebTab *tab);
    QVector<WebTab*> tabsInGroup(const QString &id) const;

    static QStringList approvedSwatchColors();
    static bool isValidGroupId(const QString &id);
    static QString sanitizedGroupName(const QString &name);
    static QString normalizedSwatchColor(const QString &color);

Q_SIGNALS:
    void groupAdded(const QString &groupId);
    void groupRemoved(const QString &groupId);
    void groupChanged(const QString &groupId);
    void tabGroupChanged(WebTab *tab);

private:
    struct Group
    {
        QString id;
        QString name;
        QString color;
        bool collapsed = false;
        QVector<QPointer<WebTab>> members;
    };

    int groupRow(const QString &id) const;
    Group *groupForId(const QString &id);
    const Group *groupForId(const QString &id) const;
    QString createUniqueGroupId() const;
    void emitGroupChanged(int row, const QVector<int> &roles);
    void tabDestroyed(QObject *object);

    QVector<Group> m_groups;
    QHash<WebTab*, QString> m_tabGroups;
};
