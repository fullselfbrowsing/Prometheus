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
#include <QFontMetrics>
#include <QHelpEvent>
#include <QPainter>
#include <QPen>
#include <QToolTip>

namespace {
constexpr int Padding = 8;
constexpr int Gap = 4;
constexpr int DotSize = 8;
constexpr int LabelHeight = 16;
constexpr int LabelMinWidth = 20;
constexpr int BadgeLabelSpace = 108;
constexpr int GroupRailHeight = 2;
constexpr int GroupLabelHeight = 24;
constexpr int GroupLabelMinWidth = 32;
constexpr int GroupLabelMaxWidth = 76;
constexpr int GroupLabelMaxLength = 24;

const QColor AccentColor(QSL("#ff6b35"));
const QColor DestructiveColor(QSL("#ff6666"));
const QColor DefaultGroupColor(QSL("#3a7bd5"));

QList<QColor> approvedGroupColors()
{
    return {
        QColor(QSL("#3a7bd5")),
        QColor(QSL("#2f9e7e")),
        QColor(QSL("#9b6ade")),
        QColor(QSL("#d29b36")),
        QColor(QSL("#a65b5b"))
    };
}

bool sameColor(const QColor &left, const QColor &right)
{
    return left.isValid() && right.isValid() && left.rgb() == right.rgb();
}

QColor approvedGroupColor(const QVariant &value)
{
    QColor color = value.value<QColor>();
    if (!color.isValid()) {
        color = QColor(value.toString());
    }

    const QList<QColor> swatches = approvedGroupColors();
    for (const QColor &swatch : swatches) {
        if (sameColor(color, swatch)) {
            return swatch;
        }
    }

    return DefaultGroupColor;
}

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

QString boundedGroupLabel(const QModelIndex &index)
{
    return boundedBadgeText(index.data(TabModel::TabGroupNameRole).toString(), GroupLabelMaxLength);
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

    const bool hovered = opt.state & QStyle::State_MouseOver;
    const bool selected = opt.state & QStyle::State_Selected;
    const bool current = index.data(TabModel::CurrentTabRole).toBool();
    if (hovered || selected || current) {
        painter->save();
        painter->setRenderHint(QPainter::Antialiasing, true);
        QColor fill = opt.palette.color(QPalette::Text);
        fill.setAlpha(current || selected ? 36 : 18);
        painter->setPen(Qt::NoPen);
        painter->setBrush(fill);
        const QRect pillRect = opt.rect.adjusted(2, 2, -2, -2);
        painter->drawRoundedRect(pillRect, pillRect.height() / 2, pillRect.height() / 2);
        painter->restore();
    }

    const QRect contentRect = opt.rect.adjusted(Padding, 0, -Padding, 0);
    const int centerY = contentRect.center().y();
    int left = contentRect.left();
    int right = contentRect.right();
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    const bool grouped = !groupId.isEmpty();
    const bool groupCollapsed = index.data(TabModel::TabGroupCollapsedRole).toBool();
    const QString groupLabel = boundedGroupLabel(index);
    const QColor groupColor = approvedGroupColor(index.data(TabModel::TabGroupColorRole));

    if (grouped) {
        painter->save();
        painter->fillRect(QRect(opt.rect.left(), opt.rect.top(), opt.rect.width(), GroupRailHeight), groupColor);
        painter->restore();
    }

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

    if (grouped && groupCollapsed && right > left) {
        painter->save();
        QColor chipFill = groupColor;
        chipFill.setAlpha(36);
        painter->setPen(QPen(groupColor, 1));
        painter->setBrush(chipFill);
        painter->drawRoundedRect(QRect(left, centerY - GroupLabelHeight / 2, right - left + 1, GroupLabelHeight), GroupLabelHeight / 2, GroupLabelHeight / 2);
        painter->restore();
    }

    const QRect iconRect(left, centerY - IconSize / 2, IconSize, IconSize);
    const QIcon icon = index.data(TabModel::IconRole).value<QIcon>();
    if (!icon.isNull()) {
        painter->drawPixmap(iconRect, icon.pixmap(IconSize, IconSize));
    }
    left = iconRect.right() + Gap + 1;

    if (m_tabDisplay == QzSettings::TabDisplay::TitleAndIcon && right > left) {
        QFont groupFont = opt.font;
        groupFont.setWeight(QFont::DemiBold);
        QFontMetrics groupMetrics(groupFont);
        if (grouped && !groupCollapsed && !groupLabel.isEmpty()) {
            const int available = right - left + 1;
            const int labelWidth = qMin(qMin(GroupLabelMaxWidth, available), qMax(GroupLabelMinWidth, groupMetrics.horizontalAdvance(groupLabel) + Gap * 3));
            if (labelWidth >= GroupLabelMinWidth && available >= labelWidth + Gap + LabelMinWidth) {
                const QRect labelRect(left, centerY - GroupLabelHeight / 2, labelWidth, GroupLabelHeight);
                painter->save();
                QColor labelFill = groupColor;
                labelFill.setAlpha(42);
                painter->setPen(QPen(groupColor, 1));
                painter->setBrush(labelFill);
                painter->drawRoundedRect(labelRect, GroupLabelHeight / 2, GroupLabelHeight / 2);
                painter->setFont(groupFont);
                painter->setPen(opt.palette.color(QPalette::Text));
                painter->drawText(labelRect.adjusted(Gap, 0, -Gap, 0), Qt::AlignCenter, groupMetrics.elidedText(groupLabel, Qt::ElideRight, labelRect.width() - Gap * 2));
                painter->restore();
                left = labelRect.right() + Gap + 1;
            }
        }

        const QRect titleRect(left, opt.rect.top(), right - left + 1, opt.rect.height());
        const QString sourceTitle = groupCollapsed && !groupLabel.isEmpty() ? groupLabel : index.data(TabModel::TitleRole).toString();
        const QString title = opt.fontMetrics.elidedText(sourceTitle, Qt::ElideRight, titleRect.width());
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
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    if (!groupId.isEmpty()) {
        const QString groupLabel = boundedGroupLabel(index);
        if (!groupLabel.isEmpty()) {
            parts.append(index.data(TabModel::TabGroupCollapsedRole).toBool()
                    ? tr("Collapsed group: %1").arg(groupLabel)
                    : tr("Group: %1").arg(groupLabel));
        }
    }
    for (const Badge &badge : badgesForIndex(index)) {
        if (!badge.tooltip.isEmpty()) {
            parts.append(badge.tooltip);
        }
    }
    return parts.join(QSL("\n"));
}
