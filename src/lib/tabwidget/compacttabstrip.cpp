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
#include "compacttabstrip.h"
#include "browserwindow.h"
#include "compacttabdelegate.h"
#include "compacttabfiltermodel.h"
#include "mainapplication.h"
#include "tabcontextmenu.h"
#include "tabmodel.h"
#include "tabmrumodel.h"
#include "tabwidget.h"
#include "webtab.h"

#include <QContextMenuEvent>
#include <QMouseEvent>

CompactTabStrip::CompactTabStrip(BrowserWindow *window, QWidget *parent)
    : QListView(parent)
    , m_window(window)
    , m_filterModel(new CompactTabFilterModel(this))
    , m_delegate(new CompactTabDelegate(this))
{
    setObjectName(QSL("compact-tab-strip"));
    setAccessibleName(tr("Compact Tabs"));

    m_filterModel->setSourceModel(m_window ? m_window->tabModel() : nullptr);
    m_filterModel->setMruModel(m_window ? m_window->tabMruModel() : nullptr);

    setModel(m_filterModel);
    setItemDelegate(m_delegate);
    setIconSize(QSize(CompactTabDelegate::IconSize, CompactTabDelegate::IconSize));

    setFlow(QListView::LeftToRight);
    setWrapping(false);
    setMovement(QListView::Static);
    setResizeMode(QListView::Adjust);
    setLayoutMode(QListView::SinglePass);
    setUniformItemSizes(true);
    setEditTriggers(QAbstractItemView::NoEditTriggers);
    setSelectionMode(QAbstractItemView::NoSelection);
    setFocusPolicy(Qt::NoFocus);
    setFrameShape(QFrame::NoFrame);

    setDragEnabled(true);
    setAcceptDrops(true);
    setDropIndicatorShown(true);
    setDragDropMode(QAbstractItemView::InternalMove);
    setDefaultDropAction(Qt::MoveAction);

    setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    setHorizontalScrollMode(QAbstractItemView::ScrollPerPixel);
    setVerticalScrollMode(QAbstractItemView::ScrollPerPixel);
    setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);

    connect(this, &QListView::clicked, this, &CompactTabStrip::activateIndex);
    if (mApp) {
        connect(mApp, &MainApplication::settingsReloaded, this, &CompactTabStrip::refreshDisplayMode);
    }

    refreshDisplayMode();
}

void CompactTabStrip::refreshDisplayMode()
{
    m_delegate->loadSettings();
    updateGridSize();
    viewport()->update();
    updateGeometry();
}

QSize CompactTabStrip::sizeHint() const
{
    return QSize(CompactTabDelegate::PreferredTabWidth * 3, CompactTabDelegate::RowHeight);
}

QSize CompactTabStrip::minimumSizeHint() const
{
    return QSize(CompactTabDelegate::MinimumTabWidth, CompactTabDelegate::RowHeight);
}

void CompactTabStrip::activateIndex(const QModelIndex &index)
{
    WebTab *tab = webTabForIndex(index);
    if (tab) {
        tab->makeCurrentTab();
    }
}

void CompactTabStrip::requestCloseIndex(const QModelIndex &index)
{
    WebTab *tab = webTabForIndex(index);
    if (!tab || !m_window || !m_window->tabWidget()) {
        return;
    }

    m_window->tabWidget()->requestCloseTab(tab->tabIndex());
}

void CompactTabStrip::openContextMenu(const QPoint &position)
{
    if (!m_window) {
        return;
    }

    WebTab *tab = webTabForIndex(indexAt(position));
    const int tabIndex = tab ? tab->tabIndex() : -1;
    TabContextMenu menu(tabIndex, m_window);
    menu.exec(viewport()->mapToGlobal(position));
}

void CompactTabStrip::updateGridSize()
{
    const int width = m_delegate->tabDisplay() == QzSettings::TabDisplay::FaviconOnly
            ? CompactTabDelegate::FaviconOnlyWidth
            : CompactTabDelegate::PreferredTabWidth;
    setGridSize(QSize(width, CompactTabDelegate::RowHeight));
    setMinimumHeight(CompactTabDelegate::RowHeight);
    setMaximumHeight(CompactTabDelegate::RowHeight);
}

WebTab *CompactTabStrip::webTabForIndex(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return nullptr;
    }
    return index.data(TabModel::WebTabRole).value<WebTab*>();
}

bool CompactTabStrip::viewportEvent(QEvent *event)
{
    switch (event->type()) {
    case QEvent::MouseButtonPress: {
        auto *mouseEvent = static_cast<QMouseEvent*>(event);
        if (mouseEvent->button() == Qt::MiddleButton) {
            requestCloseIndex(indexAt(mouseEvent->pos()));
            mouseEvent->accept();
            return true;
        }
        break;
    }

    case QEvent::ContextMenu: {
        auto *contextEvent = static_cast<QContextMenuEvent*>(event);
        openContextMenu(contextEvent->pos());
        contextEvent->accept();
        return true;
    }

    default:
        break;
    }

    return QListView::viewportEvent(event);
}
