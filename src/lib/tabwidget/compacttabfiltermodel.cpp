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

#include <QAbstractItemModel>
#include <QMimeData>

CompactTabFilterModel::CompactTabFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
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
    return !index.data(TabModel::CurrentTabRole).toBool();
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
