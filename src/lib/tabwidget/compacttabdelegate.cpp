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
#include "compacttabdelegate.h"
#include "tabmodel.h"

#include <QAbstractItemView>
#include <QApplication>
#include <QHelpEvent>
#include <QPainter>
#include <QToolTip>

namespace {
constexpr int Padding = 8;
constexpr int Gap = 4;
constexpr int DotSize = 8;
constexpr int LabelHeight = 16;
constexpr int LabelMinWidth = 20;
constexpr int BadgeLabelSpace = 108;

const QColor AccentColor(QSL("#ff6b35"));
const QColor DestructiveColor(QSL("#ff6666"));

bool isUnhealthy(const QString &health)
{
    const QString normalized = health.trimmed().toLower();
    return !normalized.isEmpty() && normalized != QL1S("ok");
}

QString boundedBadgeText(const QString &text, int maxLength)
{
    QString normalized = text.simplified();
    if (normalized.size() <= maxLength) {
        return normalized;
    }
    return normalized.left(qMax(0, maxLength - 3)) + QSL("...");
}
}

CompactTabDelegate::CompactTabDelegate(QObject *parent)
    : QStyledItemDelegate(parent)
{
    loadSettings();
}

void CompactTabDelegate::loadSettings()
{
    if (qzSettings) {
        m_tabDisplay = qzSettings->tabDisplay;
    }
}

void CompactTabDelegate::setTabDisplay(QzSettings::TabDisplay display)
{
    m_tabDisplay = display;
}

QzSettings::TabDisplay CompactTabDelegate::tabDisplay() const
{
    return m_tabDisplay;
}

void CompactTabDelegate::paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const
{
    QStyleOptionViewItem opt(option);
    initStyleOption(&opt, index);
    opt.text.clear();
    opt.decorationSize = QSize(IconSize, IconSize);

    const QWidget *widget = opt.widget;
    const QStyle *style = widget ? widget->style() : QApplication::style();

    style->drawPrimitive(QStyle::PE_PanelItemViewItem, &opt, painter, widget);

    const QRect contentRect = opt.rect.adjusted(Padding, 0, -Padding, 0);
    const int centerY = contentRect.center().y();
    int left = contentRect.left();
    int right = contentRect.right();

    const QList<Badge> badges = badgesForIndex(index);
    const bool labelBadges = m_tabDisplay == QzSettings::TabDisplay::TitleAndIcon
            && contentRect.width() >= BadgeLabelSpace;

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    for (auto it = badges.crbegin(); it != badges.crend(); ++it) {
        const int badgeWidth = labelBadges
                ? qMax(LabelMinWidth, opt.fontMetrics.horizontalAdvance(it->text) + Gap * 3)
                : DotSize;
        const QRect badgeRect(right - badgeWidth + 1, centerY - (labelBadges ? LabelHeight : DotSize) / 2, badgeWidth, labelBadges ? LabelHeight : DotSize);
        paintBadge(painter, *it, badgeRect, opt.palette, !labelBadges);
        right = badgeRect.left() - Gap;
    }
    painter->restore();

    const QRect iconRect(left, centerY - IconSize / 2, IconSize, IconSize);
    const QIcon icon = index.data(TabModel::IconRole).value<QIcon>();
    if (!icon.isNull()) {
        painter->drawPixmap(iconRect, icon.pixmap(IconSize, IconSize));
    }
    left = iconRect.right() + Gap + 1;

    if (m_tabDisplay == QzSettings::TabDisplay::TitleAndIcon && right > left) {
        const QRect titleRect(left, opt.rect.top(), right - left + 1, opt.rect.height());
        const QString title = opt.fontMetrics.elidedText(index.data(TabModel::TitleRole).toString(), Qt::ElideRight, titleRect.width());
        const QPalette::ColorRole colorRole = opt.state & QStyle::State_Selected ? QPalette::HighlightedText : QPalette::Text;
        style->drawItemText(painter, titleRect, Qt::AlignVCenter | Qt::AlignLeft, opt.palette, opt.state & QStyle::State_Enabled, title, colorRole);
    }

    if (opt.state & QStyle::State_HasFocus) {
        painter->save();
        QPen pen(AccentColor);
        pen.setWidth(1);
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        painter->drawRoundedRect(opt.rect.adjusted(1, 1, -2, -2), 4, 4);
        painter->restore();
    }
}

QSize CompactTabDelegate::sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const
{
    Q_UNUSED(option)
    const bool iconOnly = m_tabDisplay == QzSettings::TabDisplay::FaviconOnly || index.data(TabModel::PinnedRole).toBool();
    return QSize(iconOnly ? FaviconOnlyWidth : PreferredTabWidth, RowHeight);
}

bool CompactTabDelegate::helpEvent(QHelpEvent *event, QAbstractItemView *view, const QStyleOptionViewItem &option, const QModelIndex &index)
{
    Q_UNUSED(option)

    if (!event || !view || !index.isValid()) {
        return QStyledItemDelegate::helpEvent(event, view, option, index);
    }

    const QString tooltip = tooltipForIndex(index);
    if (tooltip.isEmpty()) {
        return QStyledItemDelegate::helpEvent(event, view, option, index);
    }

    QToolTip::showText(event->globalPos(), tooltip, view);
    return true;
}

QList<CompactTabDelegate::Badge> CompactTabDelegate::badgesForIndex(const QModelIndex &index) const
{
    QList<Badge> badges;

    const QString owner = index.data(TabModel::TabOwnerRole).toString().simplified();
    if (!owner.isEmpty()) {
        badges.append({
            boundedBadgeText(owner, 10),
            tr("Owned by %1").arg(boundedBadgeText(owner, 32)),
            QColor(QSL("#606060")),
            false,
            false
        });
    }

    if (index.data(TabModel::ActiveAutomationRole).toBool()) {
        badges.append({tr("A"), tr("Active automation"), AccentColor, true, false});
    }

    if (index.data(TabModel::SupervisionRole).toBool()) {
        badges.append({tr("S"), tr("Supervised session active"), AccentColor, true, false});
    }

    const QString health = index.data(TabModel::TabHealthRole).toString();
    if (isUnhealthy(health)) {
        badges.append({
            tr("!"),
            tr("Tab health: %1").arg(boundedBadgeText(health, 32)),
            DestructiveColor,
            false,
            true
        });
    }

    return badges;
}

void CompactTabDelegate::paintBadge(QPainter *painter, const Badge &badge, const QRect &rect, const QPalette &palette, bool compact) const
{
    if (compact) {
        painter->setPen(Qt::NoPen);
        painter->setBrush(badge.color);
        painter->drawEllipse(rect);
        return;
    }

    QColor fill = badge.color;
    if (!badge.accent && !badge.destructive) {
        fill = palette.color(QPalette::Window).darker(125);
    }

    painter->setPen(Qt::NoPen);
    painter->setBrush(fill);
    painter->drawRoundedRect(rect, rect.height() / 2, rect.height() / 2);

    const QColor textColor = (badge.accent || badge.destructive) ? QColor(Qt::white) : palette.color(QPalette::Text);
    painter->setPen(textColor);
    painter->drawText(rect.adjusted(Gap, 0, -Gap, 0), Qt::AlignCenter, badge.text);
}

QString CompactTabDelegate::tooltipForIndex(const QModelIndex &index) const
{
    QStringList parts;
    for (const Badge &badge : badgesForIndex(index)) {
        if (!badge.tooltip.isEmpty()) {
            parts.append(badge.tooltip);
        }
    }
    return parts.join(QSL("\n"));
}
