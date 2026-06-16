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

#include <QColor>
#include <QList>
#include <QStyledItemDelegate>

class QAbstractItemView;
class QHelpEvent;
class QPainter;

class FALKON_EXPORT TabSearchDelegate : public QStyledItemDelegate
{
    Q_OBJECT

public:
    explicit TabSearchDelegate(QObject *parent = nullptr);

    void paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const override;
    QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const override;
    bool helpEvent(QHelpEvent *event, QAbstractItemView *view, const QStyleOptionViewItem &option, const QModelIndex &index) override;

    static constexpr int RowHeight = 32;
    static constexpr int IconSize = 16;

private:
    struct Badge {
        QString text;
        QString tooltip;
        QColor color;
        bool accent = false;
        bool destructive = false;
    };

    QList<Badge> badgesForIndex(const QModelIndex &index) const;
    void paintBadge(QPainter *painter, const Badge &badge, const QRect &rect, const QPalette &palette) const;
    QString domainTextForIndex(const QModelIndex &index) const;
    QString tooltipForIndex(const QModelIndex &index) const;
};
