/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2014-2018 David Rosca <nowrep@gmail.com>
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
#ifndef PROMETHEUSSTARTBRIDGE_H
#define PROMETHEUSSTARTBRIDGE_H

#include "qzcommon.h"
#include <QObject>
#include <QPointer>

class BrowserWindow;
class WebPage;

class FALKON_EXPORT PrometheusStartBridge : public QObject
{
    Q_OBJECT
public:
    // page is the owning WebPage; each privileged slot verifies page->url()
    // == falkon:start at call time (the registration-time URL guard was always
    // false because url() is empty during WebPage construction).
    explicit PrometheusStartBridge(BrowserWindow* window, WebPage* page, QObject* parent = nullptr);

public Q_SLOTS:
    void openAgentWithPrompt(const QString& prompt);
    void navigateTo(const QString& url);
    QString bookmarkFavoritesJson() const;
    QString currentTheme() const;

private:
    // QPointer zeroes itself when BrowserWindow is destroyed, making the
    // existing null-guard safe against in-flight event-loop messages after
    // window close (WR-02).
    QPointer<BrowserWindow> m_window;
    // Raw pointer is safe: bridge is owned by QWebChannel which is owned by
    // WebPage — they are destroyed together, so m_page is never dangling.
    WebPage* m_page;
};

#endif // PROMETHEUSSTARTBRIDGE_H
