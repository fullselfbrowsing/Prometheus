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
    invalidateFilter();
}

QString TabSearchFilterModel::groupFilter() const
{
    return m_groupFilter;
}

void TabSearchFilterModel::setGroupFilter(const QString &group)
{
    const QString normalized = normalizedFilterText(group);
    if (m_groupFilter == normalized) {
        return;
    }

    m_groupFilter = normalized;
    invalidateFilter();
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

    if (!m_groupFilter.isEmpty()) {
        const QString groupText = sourceIndex.data(Qt::UserRole + 15).toString().simplified().toCaseFolded();
        if (groupText.isEmpty() || !groupText.contains(m_groupFilter)) {
            return false;
        }
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
