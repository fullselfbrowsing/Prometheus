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
#include "compacttabfiltermodel.h"
#include "tabmodel.h"
#include "webtab.h"

#include <QAbstractItemModel>
#include <QMimeData>

CompactTabFilterModel::CompactTabFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void CompactTabFilterModel::setMruModel(QAbstractItemModel *model)
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
        };
        connect(m_mruModel, &QAbstractItemModel::dataChanged, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::layoutChanged, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::modelReset, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsInserted, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsMoved, this, invalidateRows);
        connect(m_mruModel, &QAbstractItemModel::rowsRemoved, this, invalidateRows);
    }

    invalidate();
}

Qt::DropActions CompactTabFilterModel::supportedDropActions() const
{
    return sourceModel() ? sourceModel()->supportedDropActions() : Qt::IgnoreAction;
}

QStringList CompactTabFilterModel::mimeTypes() const
{
    return sourceModel() ? sourceModel()->mimeTypes() : QStringList();
}

QMimeData *CompactTabFilterModel::mimeData(const QModelIndexList &indexes) const
{
    if (!sourceModel()) {
        return nullptr;
    }

    QModelIndexList sourceIndexes;
    sourceIndexes.reserve(indexes.size());
    for (const QModelIndex &index : indexes) {
        const QModelIndex sourceIndex = mapToSource(index);
        if (sourceIndex.isValid()) {
            sourceIndexes.append(sourceIndex);
        }
    }

    return sourceModel()->mimeData(sourceIndexes);
}

bool CompactTabFilterModel::canDropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent) const
{
    if (!sourceModel() || parent.isValid()) {
        return false;
    }

    return sourceModel()->canDropMimeData(data, action, sourceDropRowForProxyRow(row), column, QModelIndex());
}

bool CompactTabFilterModel::dropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent)
{
    if (!sourceModel() || parent.isValid()) {
        return false;
    }

    return sourceModel()->dropMimeData(data, action, sourceDropRowForProxyRow(row), column, QModelIndex());
}

bool CompactTabFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!sourceModel()) {
        return false;
    }

    const QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    if (groupId.isEmpty()) {
        return !index.data(TabModel::CurrentTabRole).toBool();
    }

    const bool collapsed = index.data(TabModel::TabGroupCollapsedRole).toBool();
    if (!collapsed) {
        return !index.data(TabModel::CurrentTabRole).toBool();
    }

    return sourceRow == representativeSourceRowForGroup(groupId, sourceParent);
}

int CompactTabFilterModel::sourceDropRowForProxyRow(int row) const
{
    if (!sourceModel()) {
        return -1;
    }

    if (row < 0) {
        return -1;
    }

    if (row >= rowCount()) {
        return sourceModel()->rowCount();
    }

    const QModelIndex sourceIndex = mapToSource(index(row, 0));
    return sourceIndex.isValid() ? sourceIndex.row() : sourceModel()->rowCount();
}

int CompactTabFilterModel::representativeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
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

int CompactTabFilterModel::activeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
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

int CompactTabFilterModel::mruSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
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

int CompactTabFilterModel::firstSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const
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

int CompactTabFilterModel::sourceRowForTabVariant(const QVariant &tabVariant, const QModelIndex &sourceParent) const
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
