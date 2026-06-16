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
#include "tabsearchfiltermodel.h"
#include "tabmodel.h"
#include "webtab.h"

#include <QUrl>

namespace {
constexpr int MaxFilterLength = 256;
const QString UngroupedFilter = QSL("__prometheus_ungrouped__");
}

TabSearchFilterModel::TabSearchFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    sort(0);
}

QString TabSearchFilterModel::filterText() const
{
    return m_filterText;
}

void TabSearchFilterModel::setFilterText(const QString &text)
{
    const QString normalized = normalizedFilterText(text);
    if (m_filterText == normalized) {
        return;
    }

    m_filterText = normalized;
    m_filterTerms = m_filterText.split(QL1C(' '), Qt::SkipEmptyParts);
    invalidate();
}

QString TabSearchFilterModel::groupFilter() const
{
    return m_groupFilter;
}

void TabSearchFilterModel::setGroupFilter(const QString &group)
{
    const QString normalized = normalizedGroupFilter(group);
    if (m_groupFilter == normalized) {
        return;
    }

    m_groupFilter = normalized;
    invalidate();
}

QString TabSearchFilterModel::ungroupedGroupFilter()
{
    return UngroupedFilter;
}

void TabSearchFilterModel::setGroupSectionsEnabled(bool enabled)
{
    if (m_groupSectionsEnabled == enabled) {
        return;
    }

    m_groupSectionsEnabled = enabled;
    invalidate();
    sort(0);
}

void TabSearchFilterModel::setMruModel(QAbstractItemModel *model)
{
    if (m_mruModel == model) {
        return;
    }

    if (m_mruModel) {
        disconnect(m_mruModel, nullptr, this, nullptr);
    }

    m_mruModel = model;

    if (m_mruModel) {
        const auto invalidateRows = [this]() {
            invalidate();
            sort(0);
        };
        connect(m_mruModel, &QAbstractItemModel::dataChanged, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::layoutChanged, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::modelReset, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsInserted, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsMoved, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsRemoved, this, invalidateRows);
    }

    invalidate();
    sort(0);
}

WebTab *TabSearchFilterModel::tab(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return nullptr;
    }
    return index.data(TabModel::WebTabRole).value<WebTab*>();
}

bool TabSearchFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!sourceModel()) {
        return false;
    }

    const QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!sourceIndex.isValid()) {
        return false;
    }

    const QString groupId = sourceIndex.data(TabModel::TabGroupIdRole).toString();
    if (m_groupFilter == UngroupedFilter) {
        if (!groupId.isEmpty()) {
            return false;
        }
    } else if (!m_groupFilter.isEmpty()) {
        if (groupId != m_groupFilter) {
            return false;
        }
    }

    if (!groupId.isEmpty() && sourceIndex.data(TabModel::TabGroupCollapsedRole).toBool()
            && sourceRow != representativeSourceRowForGroup(groupId, sourceParent)) {
        return false;
    }

    if (m_filterTerms.isEmpty()) {
        return true;
    }

    const QString haystack = searchableText(sourceIndex);
    for (const QString &term : m_filterTerms) {
        if (!haystack.contains(term)) {
            return false;
        }
    }

    return true;
}

bool TabSearchFilterModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    if (m_groupSectionsEnabled) {
        const QString leftGroup = sourceLeft.data(TabModel::TabGroupIdRole).toString();
        const QString rightGroup = sourceRight.data(TabModel::TabGroupIdRole).toString();
        if (leftGroup != rightGroup) {
            const QModelIndex parent = sourceLeft.parent();
            const int leftOrder = groupSectionOrder(leftGroup, parent);
            const int rightOrder = groupSectionOrder(rightGroup, parent);
            if (leftOrder != rightOrder) {
                return leftOrder < rightOrder;
            }
        }
    }

    return sourceLeft.row() < sourceRight.row();
}

QString TabSearchFilterModel::searchableText(const QModelIndex &sourceIndex) const
{
    QStringList parts;
    parts.reserve(4);

    parts.append(sourceIndex.data(TabModel::TitleRole).toString());

    auto *tab = sourceIndex.data(TabModel::WebTabRole).value<WebTab*>();
    if (tab) {
        const QUrl url = tab->url();
        parts.append(url.toString(QUrl::FullyEncoded));
        parts.append(url.toDisplayString(QUrl::RemovePassword));
        parts.append(url.host());
    }

    return normalizedFilterText(parts.join(QL1C(' ')));
}

QString TabSearchFilterModel::normalizedFilterText(const QString &text) const
{
    return text.left(MaxFilterLength).simplified().toCaseFolded();
}

QString TabSearchFilterModel::normalizedGroupFilter(const QString &group) const
{
    if (group == UngroupedFilter) {
        return UngroupedFilter;
    }
    return group.left(MaxFilterLength).simplified();
}

int TabSearchFilterModel::representativeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
{
    int row = activeSourceRowForGroup(groupId, sourceParent);
    if (row >= 0) {
        return row;
    }

    row = mruSourceRowForGroup(groupId, sourceParent);
    if (row >= 0) {
        return row;
    }

    return firstSourceRowForGroup(groupId, sourceParent);
}

int TabSearchFilterModel::activeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
{
    if (!sourceModel() || groupId.isEmpty()) {
        return -1;
    }

    const int rows = sourceModel()->rowCount(sourceParent);
    for (int row = 0; row < rows; ++row) {
        const QModelIndex index = sourceModel()->index(row, 0, sourceParent);
        if (index.data(TabModel::TabGroupIdRole).toString() == groupId && index.data(TabModel::CurrentTabRole).toBool()) {
            return row;
        }
    }

    return -1;
}

int TabSearchFilterModel::mruSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
{
    if (!sourceModel() || !m_mruModel || groupId.isEmpty()) {
        return -1;
    }

    const int rows = m_mruModel->rowCount();
    for (int row = 0; row < rows; ++row) {
        const QModelIndex mruIndex = m_mruModel->index(row, 0);
        if (mruIndex.data(TabModel::TabGroupIdRole).toString() != groupId) {
            continue;
        }

        const int sourceRow = sourceRowForTabVariant(mruIndex.data(TabModel::WebTabRole), sourceParent);
        if (sourceRow >= 0) {
            return sourceRow;
        }
    }

    return -1;
}

int TabSearchFilterModel::firstSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
{
    if (!sourceModel() || groupId.isEmpty()) {
        return -1;
    }

    const int rows = sourceModel()->rowCount(sourceParent);
    for (int row = 0; row < rows; ++row) {
        const QModelIndex index = sourceModel()->index(row, 0, sourceParent);
        if (index.data(TabModel::TabGroupIdRole).toString() == groupId) {
            return row;
        }
    }

    return -1;
}

int TabSearchFilterModel::sourceRowForTabVariant(const QVariant &tabVariant, const QModelIndex &sourceParent) const
{
    if (!sourceModel()) {
        return -1;
    }

    WebTab *tab = tabVariant.value<WebTab*>();
    if (!tab) {
        return -1;
    }

    const int rows = sourceModel()->rowCount(sourceParent);
    for (int row = 0; row < rows; ++row) {
        const QModelIndex index = sourceModel()->index(row, 0, sourceParent);
        if (index.data(TabModel::WebTabRole).value<WebTab*>() == tab) {
            return row;
        }
    }

    return -1;
}

int TabSearchFilterModel::groupSectionOrder(const QString &groupId, const QModelIndex &sourceParent) const
{
    if (!sourceModel()) {
        return 0;
    }

    const int rows = sourceModel()->rowCount(sourceParent);
    for (int row = 0; row < rows; ++row) {
        const QModelIndex index = sourceModel()->index(row, 0, sourceParent);
        if (index.data(TabModel::TabGroupIdRole).toString() == groupId) {
            return row;
        }
    }

    return rows;
}
