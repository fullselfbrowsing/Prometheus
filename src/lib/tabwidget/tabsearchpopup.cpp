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
#include "tabsearchpopup.h"
#include "browserwindow.h"
#include "tabmrumodel.h"
#include "tabmodel.h"
#include "tabsearchdelegate.h"
#include "tabsearchfiltermodel.h"
#include "tabwidget.h"
#include "webtab.h"

#include <QAbstractItemModel>
#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QEvent>
#include <QHBoxLayout>
#include <QKeyEvent>
#include <QLabel>
#include <QLineEdit>
#include <QListView>
#include <QPersistentModelIndex>
#include <QStackedWidget>
#include <QStyle>
#include <QTimer>
#include <QVBoxLayout>

namespace {
constexpr int PopupWidth = 520;
constexpr int PopupMaxHeight = 420;
constexpr int PopupPadding = 8;
constexpr int PopupSpacing = 4;
constexpr int EmptyStateIndex = 0;
constexpr int ListStateIndex = 1;

bool isNavigationKey(int key)
{
    return key == Qt::Key_Up
            || key == Qt::Key_Down
            || key == Qt::Key_PageUp
            || key == Qt::Key_PageDown
            || key == Qt::Key_Home
            || key == Qt::Key_End;
}
}

TabSearchPopup::TabSearchPopup(BrowserWindow *window, QWidget *parent)
    : QFrame(parent, Qt::Popup)
    , m_window(window)
    , m_filterModel(new TabSearchFilterModel(this))
    , m_delegate(new TabSearchDelegate(this))
    , m_searchEdit(new QLineEdit(this))
    , m_mruOrder(new QCheckBox(tr("MRU"), this))
    , m_groupFilter(new QComboBox(this))
    , m_view(new QListView(this))
    , m_titleLabel(new QLabel(this))
    , m_emptyTitle(new QLabel(tr("No tabs found"), this))
    , m_emptyBody(new QLabel(tr("Clear the search or open a new tab group."), this))
    , m_stack(new QStackedWidget(this))
{
    setObjectName(QSL("TabSearchPopup"));
    setFrameShape(QFrame::StyledPanel);
    setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Maximum);

    m_titleLabel->setObjectName(QSL("tabSearchPopupTitle"));
    QFont titleFont = m_titleLabel->font();
    titleFont.setWeight(QFont::DemiBold);
    m_titleLabel->setFont(titleFont);

    m_searchEdit->setClearButtonEnabled(true);
    m_searchEdit->setPlaceholderText(tr("Search Tabs"));
    m_searchEdit->installEventFilter(this);

    m_mruOrder->setToolTip(tr("Use most recently used tab order"));
    connect(m_mruOrder, &QCheckBox::toggled, this, &TabSearchPopup::updateSourceModel);

    m_groupFilter->addItem(tr("All Groups"), QString());
    m_groupFilter->setVisible(false);
    connect(m_groupFilter, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int index) {
        m_filterModel->setGroupFilter(m_groupFilter->itemData(index).toString());
        updateEmptyState();
        selectFirstVisibleRow();
    });

    auto *headerLayout = new QHBoxLayout;
    headerLayout->setContentsMargins(0, 0, 0, 0);
    headerLayout->setSpacing(PopupSpacing);
    headerLayout->addWidget(m_titleLabel, 1);
    headerLayout->addWidget(m_mruOrder);
    headerLayout->addWidget(m_groupFilter);

    m_view->setObjectName(QSL("tabSearchPopupView"));
    m_view->setModel(m_filterModel);
    m_view->setItemDelegate(m_delegate);
    m_view->setUniformItemSizes(true);
    m_view->setFrameShape(QFrame::NoFrame);
    m_view->setEditTriggers(QAbstractItemView::NoEditTriggers);
    m_view->setSelectionMode(QAbstractItemView::SingleSelection);
    m_view->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_view->setVerticalScrollMode(QAbstractItemView::ScrollPerPixel);
    m_view->installEventFilter(this);
    connect(m_view, &QListView::activated, this, &TabSearchPopup::activateCurrentIndex);

    auto *emptyWidget = new QWidget(this);
    auto *emptyLayout = new QVBoxLayout(emptyWidget);
    emptyLayout->setContentsMargins(PopupPadding, PopupPadding * 2, PopupPadding, PopupPadding * 2);
    emptyLayout->setSpacing(PopupSpacing);
    emptyLayout->addStretch();
    emptyLayout->addWidget(m_emptyTitle, 0, Qt::AlignHCenter);
    emptyLayout->addWidget(m_emptyBody, 0, Qt::AlignHCenter);
    emptyLayout->addStretch();

    QFont emptyTitleFont = m_emptyTitle->font();
    emptyTitleFont.setWeight(QFont::DemiBold);
    m_emptyTitle->setFont(emptyTitleFont);
    m_emptyBody->setWordWrap(true);
    m_emptyBody->setAlignment(Qt::AlignCenter);

    m_stack->addWidget(emptyWidget);
    m_stack->addWidget(m_view);

    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(PopupPadding, PopupPadding, PopupPadding, PopupPadding);
    layout->setSpacing(PopupSpacing);
    layout->addLayout(headerLayout);
    layout->addWidget(m_searchEdit);
    layout->addWidget(m_stack);

    connect(m_searchEdit, &QLineEdit::textChanged, this, [this](const QString &text) {
        m_filterModel->setFilterText(text);
        updateEmptyState();
        selectFirstVisibleRow();
    });

    const auto updateAfterModelChange = [this]() {
        updateEmptyState();
        selectFirstVisibleRow();
    };
    connect(m_filterModel, &QAbstractItemModel::rowsInserted, this, [updateAfterModelChange](const QModelIndex &, int, int) {
        updateAfterModelChange();
    });
    connect(m_filterModel, &QAbstractItemModel::rowsRemoved, this, [updateAfterModelChange](const QModelIndex &, int, int) {
        updateAfterModelChange();
    });
    connect(m_filterModel, &QAbstractItemModel::modelReset, this, updateAfterModelChange);
    connect(m_filterModel, &QAbstractItemModel::layoutChanged, this, [updateAfterModelChange](const QList<QPersistentModelIndex> &, QAbstractItemModel::LayoutChangeHint) {
        updateAfterModelChange();
    });

    setMode(OverviewMode);
    resize(PopupWidth, sizeHint().height());
}

TabSearchPopup::Mode TabSearchPopup::mode() const
{
    return m_mode;
}

void TabSearchPopup::setMode(Mode mode)
{
    m_mode = mode;

    if (m_mode == QuickSwitchMode) {
        m_titleLabel->setText(tr("Search Tabs"));
        m_mruOrder->setChecked(true);
        m_mruOrder->setEnabled(false);
    } else {
        m_titleLabel->setText(m_mode == OverviewMode ? tr("Tab Overview") : tr("Search Tabs"));
        m_mruOrder->setEnabled(true);
    }

    updateSourceModel();
    updateEmptyState();
    selectFirstVisibleRow();
}

void TabSearchPopup::setGroupFilters(const QStringList &groups)
{
    const QString previous = m_groupFilter->currentData().toString();
    m_groupFilter->clear();
    m_groupFilter->addItem(tr("All Groups"), QString());
    for (const QString &group : groups) {
        const QString normalized = group.simplified();
        if (!normalized.isEmpty()) {
            m_groupFilter->addItem(normalized, normalized);
        }
    }

    const int index = m_groupFilter->findData(previous);
    m_groupFilter->setCurrentIndex(index >= 0 ? index : 0);
    m_groupFilter->setVisible(m_groupFilter->count() > 1);
}

void TabSearchPopup::showOverview()
{
    setMode(OverviewMode);
    show();
}

void TabSearchPopup::showSearch()
{
    setMode(SearchMode);
    show();
}

void TabSearchPopup::showQuickSwitch()
{
    setMode(QuickSwitchMode);
    show();
}

void TabSearchPopup::popup(const QPoint &globalPosition)
{
    move(globalPosition);
    show();
}

bool TabSearchPopup::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::KeyPress) {
        auto *keyEvent = static_cast<QKeyEvent*>(event);

        if (keyEvent->key() == Qt::Key_Escape) {
            close();
            return true;
        }

        if (keyEvent->key() == Qt::Key_Return || keyEvent->key() == Qt::Key_Enter) {
            activateCurrentIndex();
            return true;
        }

        if (watched == m_searchEdit && isNavigationKey(keyEvent->key())) {
            routeNavigationKey(keyEvent);
            return true;
        }

        if (watched == m_view) {
            if ((keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() == Qt::Key_F) {
                m_searchEdit->setFocus();
                m_searchEdit->selectAll();
                return true;
            }

            const QString text = keyEvent->text();
            if (!text.isEmpty() && text.at(0).isPrint()) {
                m_searchEdit->setFocus();
                m_searchEdit->setText(m_searchEdit->text() + text);
                return true;
            }
        }
    }

    return QFrame::eventFilter(watched, event);
}

void TabSearchPopup::showEvent(QShowEvent *event)
{
    QFrame::showEvent(event);

    setFixedWidth(PopupWidth);
    setMaximumHeight(PopupMaxHeight);
    updateSourceModel();
    updateEmptyState();
    selectFirstVisibleRow();

    if (m_mode == SearchMode || m_mode == QuickSwitchMode) {
        m_searchEdit->setFocus();
        m_searchEdit->selectAll();
    } else {
        m_view->setFocus();
    }
}

void TabSearchPopup::updateSourceModel()
{
    if (!m_window) {
        m_filterModel->setSourceModel(nullptr);
        return;
    }

    QAbstractItemModel *sourceModel = nullptr;
    if (m_mode == QuickSwitchMode || m_mruOrder->isChecked()) {
        sourceModel = m_window->tabMruModel();
    } else {
        sourceModel = m_window->tabModel();
    }
    if (m_filterModel->sourceModel() != sourceModel) {
        m_filterModel->setSourceModel(sourceModel);
    }
}

void TabSearchPopup::updateEmptyState()
{
    const bool hasRows = m_filterModel->rowCount() > 0;
    m_stack->setCurrentIndex(hasRows ? ListStateIndex : EmptyStateIndex);
    m_view->setVisible(hasRows);
}

void TabSearchPopup::selectFirstVisibleRow()
{
    if (m_filterModel->rowCount() <= 0) {
        return;
    }

    const QModelIndex current = m_view->currentIndex();
    if (current.isValid() && current.row() < m_filterModel->rowCount()) {
        return;
    }

    m_view->setCurrentIndex(m_filterModel->index(0, 0));
}

void TabSearchPopup::activateCurrentIndex()
{
    WebTab *tab = currentTab();
    if (!tab) {
        return;
    }

    if (BrowserWindow *browserWindow = tab->browserWindow()) {
        if (browserWindow->isMinimized()) {
            browserWindow->showNormal();
        } else {
            browserWindow->show();
        }
        browserWindow->activateWindow();
        browserWindow->raise();
    }

    tab->makeCurrentTab();
    close();
}

void TabSearchPopup::routeNavigationKey(QKeyEvent *event)
{
    QKeyEvent copy(event->type(), event->key(), event->modifiers(), event->text(), event->isAutoRepeat(), event->count());
    QApplication::sendEvent(m_view, &copy);
}

WebTab *TabSearchPopup::currentTab() const
{
    const QModelIndex index = m_view->currentIndex();
    if (!index.isValid()) {
        return nullptr;
    }
    return index.data(TabModel::WebTabRole).value<WebTab*>();
}
