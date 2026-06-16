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
#include "tabsearchdelegate.h"
#include "tabmodel.h"
#include "webtab.h"

#include <QAbstractItemView>
#include <QApplication>
#include <QFontMetrics>
#include <QHelpEvent>
#include <QPainter>
#include <QPen>
#include <QToolTip>
#include <QUrl>

namespace {
constexpr int Padding = 8;
constexpr int Gap = 4;
constexpr int DotSize = 8;
constexpr int BadgeHeight = 16;
constexpr int BadgeMinWidth = 20;
constexpr int MaxBadgeText = 10;
constexpr int GroupRailHeight = 2;
constexpr int GroupLabelHeight = 16;
constexpr int GroupLabelMinWidth = 32;
constexpr int GroupLabelMaxWidth = 92;
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
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    if (groupId.isEmpty()) {
        return TabSearchDelegate::tr("Ungrouped");
    }
    return boundedBadgeText(index.data(TabModel::TabGroupNameRole).toString(), GroupLabelMaxLength);
}

bool startsSection(const QModelIndex &index)
{
    if (!index.isValid() || index.row() == 0) {
        return true;
    }

    const QModelIndex previous = index.model()->index(index.row() - 1, index.column(), index.parent());
    return previous.data(TabModel::TabGroupIdRole).toString() != index.data(TabModel::TabGroupIdRole).toString();
}
}

TabSearchDelegate::TabSearchDelegate(QObject *parent)
    : QStyledItemDelegate(parent)
{
}

void TabSearchDelegate::paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const
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
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    const bool grouped = !groupId.isEmpty();
    const QColor groupColor = approvedGroupColor(index.data(TabModel::TabGroupColorRole));
    const QString groupLabel = boundedGroupLabel(index);
    const bool drawSectionLabel = startsSection(index) && !groupLabel.isEmpty();

    if (grouped) {
        painter->save();
        painter->fillRect(QRect(opt.rect.left(), opt.rect.top(), opt.rect.width(), GroupRailHeight), groupColor);
        painter->restore();
    }

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    const QList<Badge> badges = badgesForIndex(index);
    for (auto it = badges.crbegin(); it != badges.crend(); ++it) {
        const int badgeWidth = it->text.isEmpty()
                ? DotSize
                : qMax(BadgeMinWidth, opt.fontMetrics.horizontalAdvance(it->text) + Gap * 3);
        const int badgeHeight = it->text.isEmpty() ? DotSize : BadgeHeight;
        const QRect badgeRect(right - badgeWidth + 1, centerY - badgeHeight / 2, badgeWidth, badgeHeight);
        paintBadge(painter, *it, badgeRect, opt.palette);
        right = badgeRect.left() - Gap;
    }
    painter->restore();

    const QRect iconRect(left, centerY - IconSize / 2, IconSize, IconSize);
    const QIcon icon = index.data(TabModel::IconRole).value<QIcon>();
    if (!icon.isNull()) {
        painter->drawPixmap(iconRect, icon.pixmap(IconSize, IconSize));
    }
    left = iconRect.right() + Gap + 1;

    if (drawSectionLabel && right > left) {
        QFont groupFont = opt.font;
        groupFont.setWeight(QFont::DemiBold);
        QFontMetrics groupMetrics(groupFont);
        const int available = right - left + 1;
        const int labelWidth = qMin(qMin(GroupLabelMaxWidth, available), qMax(GroupLabelMinWidth, groupMetrics.horizontalAdvance(groupLabel) + Gap * 3));
        if (labelWidth >= GroupLabelMinWidth && available >= labelWidth + Gap + BadgeMinWidth) {
            const QRect labelRect(left, opt.rect.top() + 2, labelWidth, GroupLabelHeight);
            painter->save();
            QColor labelFill = grouped ? groupColor : opt.palette.color(QPalette::Window).darker(115);
            if (grouped) {
                labelFill.setAlpha(42);
            }
            if (grouped) {
                painter->setPen(QPen(groupColor, 1));
            } else {
                painter->setPen(Qt::NoPen);
            }
            painter->setBrush(labelFill);
            painter->drawRoundedRect(labelRect, GroupLabelHeight / 2, GroupLabelHeight / 2);
            painter->setFont(groupFont);
            painter->setPen(opt.palette.color(QPalette::Text));
            painter->drawText(labelRect.adjusted(Gap, 0, -Gap, 0), Qt::AlignCenter, groupMetrics.elidedText(groupLabel, Qt::ElideRight, labelRect.width() - Gap * 2));
            painter->restore();
            left = labelRect.right() + Gap + 1;
        }
    }

    const int textWidth = right - left + 1;
    if (textWidth <= 0) {
        return;
    }

    QFont titleFont = opt.font;
    titleFont.setWeight(QFont::DemiBold);
    QFontMetrics titleMetrics(titleFont);
    const QRect titleRect(left, opt.rect.top() + 2, textWidth, titleMetrics.height());
    const QString title = titleMetrics.elidedText(index.data(TabModel::TitleRole).toString(), Qt::ElideRight, titleRect.width());

    QPalette textPalette = opt.palette;
    const QPalette::ColorRole titleRole = opt.state & QStyle::State_Selected ? QPalette::HighlightedText : QPalette::Text;
    painter->save();
    painter->setFont(titleFont);
    style->drawItemText(painter, titleRect, Qt::AlignLeft | Qt::AlignVCenter, textPalette, opt.state & QStyle::State_Enabled, title, titleRole);
    painter->restore();

    const QRect urlRect(left, titleRect.bottom() - 1, textWidth, opt.rect.bottom() - titleRect.bottom());
    const QString urlText = opt.fontMetrics.elidedText(domainTextForIndex(index), Qt::ElideMiddle, urlRect.width());
    style->drawItemText(painter, urlRect, Qt::AlignLeft | Qt::AlignVCenter, textPalette, opt.state & QStyle::State_Enabled, urlText, QPalette::Mid);

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

QSize TabSearchDelegate::sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const
{
    Q_UNUSED(option)
    Q_UNUSED(index)
    return QSize(240, RowHeight);
}

bool TabSearchDelegate::helpEvent(QHelpEvent *event, QAbstractItemView *view, const QStyleOptionViewItem &option, const QModelIndex &index)
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

QList<TabSearchDelegate::Badge> TabSearchDelegate::badgesForIndex(const QModelIndex &index) const
{
    QList<Badge> badges;

    const QString owner = index.data(TabModel::TabOwnerRole).toString().simplified();
    if (!owner.isEmpty()) {
        badges.append({
            boundedBadgeText(owner, MaxBadgeText),
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

void TabSearchDelegate::paintBadge(QPainter *painter, const Badge &badge, const QRect &rect, const QPalette &palette) const
{
    if (badge.text.isEmpty()) {
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

QString TabSearchDelegate::domainTextForIndex(const QModelIndex &index) const
{
    auto *tab = index.data(TabModel::WebTabRole).value<WebTab*>();
    if (!tab) {
        return QString();
    }

    const QUrl url = tab->url();
    const QString host = url.host();
    if (!host.isEmpty()) {
        return host;
    }
    return url.toDisplayString(QUrl::RemovePassword);
}

QString TabSearchDelegate::tooltipForIndex(const QModelIndex &index) const
{
    QStringList parts;
    const QString groupId = index.data(TabModel::TabGroupIdRole).toString();
    const QString groupLabel = boundedGroupLabel(index);
    if (!groupLabel.isEmpty()) {
        parts.append(groupId.isEmpty()
                ? tr("Ungrouped")
                : index.data(TabModel::TabGroupCollapsedRole).toBool()
                    ? tr("Collapsed group: %1").arg(groupLabel)
                    : tr("Group: %1").arg(groupLabel));
    }
    const QString title = index.data(TabModel::TitleRole).toString().simplified();
    const QString url = domainTextForIndex(index).simplified();
    if (!title.isEmpty()) {
        parts.append(title);
    }
    if (!url.isEmpty()) {
        parts.append(url);
    }
    for (const Badge &badge : badgesForIndex(index)) {
        if (!badge.tooltip.isEmpty()) {
            parts.append(badge.tooltip);
        }
    }
    return parts.join(QSL("\n"));
}
