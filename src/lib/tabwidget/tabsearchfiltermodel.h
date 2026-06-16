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

#include <QSortFilterProxyModel>

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

    WebTab *tab(const QModelIndex &index) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

private:
    QString searchableText(const QModelIndex &sourceIndex) const;
    QString normalizedFilterText(const QString &text) const;

    QString m_filterText;
    QStringList m_filterTerms;
    QString m_groupFilter;
};
