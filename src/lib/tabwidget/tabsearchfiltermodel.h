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

#include <QPointer>
#include <QSortFilterProxyModel>

class QAbstractItemModel;
class WebTab;

class FALKON_EXPORT TabSearchFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit TabSearchFilterModel(QObject *parent = nullptr);

    QString filterText() const;
    void setFilterText(const QString &text);

    QString groupFilter() const;
    void setGroupFilter(const QString &group);
    static QString ungroupedGroupFilter();

    void setGroupSectionsEnabled(bool enabled);
    void setMruModel(QAbstractItemModel *model);

    WebTab *tab(const QModelIndex &index) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

private:
    QString searchableText(const QModelIndex &sourceIndex) const;
    QString normalizedFilterText(const QString &text) const;
    QString normalizedGroupFilter(const QString &group) const;
    int representativeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const;
    int activeSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const;
    int mruSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const;
    int firstSourceRowForGroup(const QString &groupId, const QModelIndex &sourceParent) const;
    int sourceRowForTabVariant(const QVariant &tabVariant, const QModelIndex &sourceParent) const;
    int groupSectionOrder(const QString &groupId, const QModelIndex &sourceParent) const;

    QString m_filterText;
    QStringList m_filterTerms;
    QString m_groupFilter;
    bool m_groupSectionsEnabled = false;
    QPointer<QAbstractItemModel> m_mruModel;
};
