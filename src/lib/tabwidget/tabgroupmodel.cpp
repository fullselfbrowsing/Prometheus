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
#include "tabgroupmodel.h"
#include "webtab.h"

#include <algorithm>
#include <QUuid>

namespace {
constexpr int MaxGroupNameLength = 80;
constexpr int MaxGroupIdLength = 80;

bool isAllowedGroupIdChar(const QChar c)
{
    return c.isLetterOrNumber() || c == QLatin1Char('-') || c == QLatin1Char('_');
}
}

TabGroupModel::TabGroupModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int TabGroupModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_groups.size();
}

QVariant TabGroupModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_groups.size()) {
        return {};
    }

    const Group &group = m_groups.at(index.row());
    switch (role) {
    case IdRole:
        return group.id;
    case NameRole:
    case Qt::DisplayRole:
        return group.name;
    case ColorRole:
        return group.color;
    case CollapsedRole:
        return group.collapsed;
    case MemberCountRole:
        return group.members.size();
    default:
        return {};
    }
}

QHash<int, QByteArray> TabGroupModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(IdRole, "id");
    roles.insert(NameRole, "name");
    roles.insert(ColorRole, "color");
    roles.insert(CollapsedRole, "collapsed");
    roles.insert(MemberCountRole, "memberCount");
    return roles;
}

QString TabGroupModel::createGroup(const QString &name, const QString &color, bool collapsed)
{
    const QString id = createUniqueGroupId();
    if (!addGroup(id, name, color, collapsed)) {
        return {};
    }
    return id;
}

bool TabGroupModel::addGroup(const QString &id, const QString &name, const QString &color, bool collapsed)
{
    const QString trimmedId = id.trimmed();
    if (!isValidGroupId(trimmedId) || containsGroup(trimmedId)) {
        return false;
    }

    Group group;
    group.id = trimmedId;
    group.name = sanitizedGroupName(name);
    group.color = normalizedSwatchColor(color);
    group.collapsed = collapsed;

    const int row = m_groups.size();
    beginInsertRows(QModelIndex(), row, row);
    m_groups.append(group);
    endInsertRows();

    Q_EMIT groupAdded(trimmedId);
    return true;
}

bool TabGroupModel::removeGroup(const QString &id)
{
    const int row = groupRow(id);
    if (row < 0) {
        return false;
    }

    const QString groupId = m_groups.at(row).id;
    const QVector<QPointer<WebTab>> members = m_groups.at(row).members;
    for (const QPointer<WebTab> &tab : members) {
        if (tab) {
            m_tabGroups.remove(tab);
            Q_EMIT tabGroupChanged(tab);
        }
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_groups.remove(row);
    endRemoveRows();

    Q_EMIT groupRemoved(groupId);
    return true;
}

bool TabGroupModel::containsGroup(const QString &id) const
{
    return groupRow(id) >= 0;
}

QStringList TabGroupModel::groupIds() const
{
    QStringList ids;
    ids.reserve(m_groups.size());
    for (const Group &group : m_groups) {
        ids.append(group.id);
    }
    return ids;
}

QString TabGroupModel::groupName(const QString &id) const
{
    const Group *group = groupForId(id);
    return group ? group->name : QString();
}

QString TabGroupModel::groupColor(const QString &id) const
{
    const Group *group = groupForId(id);
    return group ? group->color : QString();
}

bool TabGroupModel::isGroupCollapsed(const QString &id) const
{
    const Group *group = groupForId(id);
    return group ? group->collapsed : false;
}

bool TabGroupModel::renameGroup(const QString &id, const QString &name)
{
    const int row = groupRow(id);
    if (row < 0) {
        return false;
    }

    const QString sanitizedName = sanitizedGroupName(name);
    if (m_groups[row].name == sanitizedName) {
        return true;
    }

    m_groups[row].name = sanitizedName;
    emitGroupChanged(row, {NameRole});
    return true;
}

bool TabGroupModel::setGroupColor(const QString &id, const QString &color)
{
    const int row = groupRow(id);
    if (row < 0) {
        return false;
    }

    const QString normalizedColor = normalizedSwatchColor(color);
    if (m_groups[row].color == normalizedColor) {
        return true;
    }

    m_groups[row].color = normalizedColor;
    emitGroupChanged(row, {ColorRole});
    return true;
}

bool TabGroupModel::setGroupCollapsed(const QString &id, bool collapsed)
{
    const int row = groupRow(id);
    if (row < 0) {
        return false;
    }
    if (m_groups[row].collapsed == collapsed) {
        return true;
    }

    m_groups[row].collapsed = collapsed;
    emitGroupChanged(row, {CollapsedRole});
    return true;
}

QString TabGroupModel::tabGroupId(WebTab *tab) const
{
    return m_tabGroups.value(tab);
}

bool TabGroupModel::setTabGroup(WebTab *tab, const QString &groupId)
{
    if (!tab) {
        return false;
    }

    const QString normalizedId = groupId.trimmed();
    if (!normalizedId.isEmpty() && !containsGroup(normalizedId)) {
        return false;
    }

    const QString oldGroupId = m_tabGroups.value(tab);
    if (oldGroupId == normalizedId) {
        return true;
    }

    const int oldRow = groupRow(oldGroupId);
    if (oldRow >= 0) {
        auto &members = m_groups[oldRow].members;
        members.erase(std::remove_if(members.begin(), members.end(), [tab](const QPointer<WebTab> &member) {
            return member == tab || member.isNull();
        }), members.end());
        emitGroupChanged(oldRow, {MemberCountRole});
    }

    if (normalizedId.isEmpty()) {
        m_tabGroups.remove(tab);
    } else {
        const int newRow = groupRow(normalizedId);
        if (newRow < 0) {
            return false;
        }
        m_tabGroups.insert(tab, normalizedId);
        auto &members = m_groups[newRow].members;
        if (!members.contains(tab)) {
            members.append(tab);
        }
        connect(tab, &QObject::destroyed, this, &TabGroupModel::tabDestroyed, Qt::UniqueConnection);
        emitGroupChanged(newRow, {MemberCountRole});
    }

    Q_EMIT tabGroupChanged(tab);
    return true;
}

bool TabGroupModel::clearTabGroup(WebTab *tab)
{
    return setTabGroup(tab, QString());
}

QVector<WebTab*> TabGroupModel::tabsInGroup(const QString &id) const
{
    QVector<WebTab*> tabs;
    const Group *group = groupForId(id);
    if (!group) {
        return tabs;
    }

    tabs.reserve(group->members.size());
    for (const QPointer<WebTab> &tab : group->members) {
        if (tab) {
            tabs.append(tab);
        }
    }
    return tabs;
}

QStringList TabGroupModel::approvedSwatchColors()
{
    return {
        QSL("#3a7bd5"),
        QSL("#2f9e7e"),
        QSL("#9b6ade"),
        QSL("#d29b36"),
        QSL("#a65b5b")
    };
}

bool TabGroupModel::isValidGroupId(const QString &id)
{
    if (id.isEmpty() || id.size() > MaxGroupIdLength) {
        return false;
    }
    for (const QChar c : id) {
        if (!isAllowedGroupIdChar(c)) {
            return false;
        }
    }
    return true;
}

QString TabGroupModel::sanitizedGroupName(const QString &name)
{
    QString sanitized = name;
    sanitized.replace(QLatin1Char('\r'), QLatin1Char(' '));
    sanitized.replace(QLatin1Char('\n'), QLatin1Char(' '));
    sanitized.replace(QLatin1Char('\t'), QLatin1Char(' '));
    sanitized = sanitized.simplified().left(MaxGroupNameLength);
    return sanitized.isEmpty() ? QSL("Tab Group") : sanitized;
}

QString TabGroupModel::normalizedSwatchColor(const QString &color)
{
    const QString normalized = color.trimmed().toLower();
    const QStringList approved = approvedSwatchColors();
    return approved.contains(normalized) ? normalized : approved.constFirst();
}

int TabGroupModel::groupRow(const QString &id) const
{
    for (int i = 0; i < m_groups.size(); ++i) {
        if (m_groups.at(i).id == id) {
            return i;
        }
    }
    return -1;
}

TabGroupModel::Group *TabGroupModel::groupForId(const QString &id)
{
    const int row = groupRow(id);
    return row >= 0 ? &m_groups[row] : nullptr;
}

const TabGroupModel::Group *TabGroupModel::groupForId(const QString &id) const
{
    const int row = groupRow(id);
    return row >= 0 ? &m_groups.at(row) : nullptr;
}

QString TabGroupModel::createUniqueGroupId() const
{
    QString id;
    do {
        id = QSL("group-") + QUuid::createUuid().toString(QUuid::WithoutBraces);
    } while (containsGroup(id));
    return id;
}

void TabGroupModel::emitGroupChanged(int row, const QVector<int> &roles)
{
    if (row < 0 || row >= m_groups.size()) {
        return;
    }
    const QModelIndex idx = index(row, 0);
    Q_EMIT dataChanged(idx, idx, roles);
    Q_EMIT groupChanged(m_groups.at(row).id);
}

void TabGroupModel::tabDestroyed(QObject *object)
{
    WebTab *tab = static_cast<WebTab*>(object);
    const QString groupId = m_tabGroups.take(tab);
    const int row = groupRow(groupId);
    if (row < 0) {
        return;
    }

    auto &members = m_groups[row].members;
    members.erase(std::remove_if(members.begin(), members.end(), [tab](const QPointer<WebTab> &member) {
        return member == tab || member.isNull();
    }), members.end());
    emitGroupChanged(row, {MemberCountRole});
}
