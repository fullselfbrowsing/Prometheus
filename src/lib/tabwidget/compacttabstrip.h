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

#include <QListView>

class BrowserWindow;
class CompactTabDelegate;
class CompactTabFilterModel;
class WebTab;

class FALKON_EXPORT CompactTabStrip : public QListView
{
    Q_OBJECT

public:
    explicit CompactTabStrip(BrowserWindow *window, QWidget *parent = nullptr);

    void refreshDisplayMode();

    QSize sizeHint() const override;
    QSize minimumSizeHint() const override;

private:
    void activateIndex(const QModelIndex &index);
    void requestCloseIndex(const QModelIndex &index);
    void openContextMenu(const QPoint &position);
    void updateGridSize();
    WebTab *webTabForIndex(const QModelIndex &index) const;

    bool viewportEvent(QEvent *event) override;

    BrowserWindow *m_window = nullptr;
    CompactTabFilterModel *m_filterModel = nullptr;
    CompactTabDelegate *m_delegate = nullptr;
};
