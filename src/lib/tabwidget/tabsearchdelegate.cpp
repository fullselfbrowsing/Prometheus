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
#include <QHelpEvent>
#include <QPainter>
#include <QToolTip>
#include <QUrl>

namespace {
constexpr int Padding = 8;
constexpr int Gap = 4;
constexpr int DotSize = 8;
constexpr int BadgeHeight = 16;
constexpr int BadgeMinWidth = 20;
constexpr int MaxBadgeText = 10;

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
