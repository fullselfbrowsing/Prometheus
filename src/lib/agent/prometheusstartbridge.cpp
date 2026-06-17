/* ============================================================
* Falkon - Qt web browser
* Copyright (C) 2014-2018 David Rosca <nowrosen@gmail.com>
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
#include "prometheusstartbridge.h"
#include "agentruntimesidebar.h"
#include "bookmarkitem.h"
#include "bookmarks.h"
#include "browserwindow.h"
#include "mainapplication.h"
#include "settings.h"
#include "sidebar.h"
#include "tabbedwebview.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QVBoxLayout>

namespace {

QString deterministicColor(const QString& host)
{
    static const QStringList pool = {
        QSL("#ff6b35"),
        QSL("#d4824a"),
        QSL("#a0522d"),
        QSL("#7b5e4b"),
        QSL("#5c4a3a")
    };
    return pool[static_cast<int>(qHash(host) % static_cast<uint>(pool.size()))];
}

} // namespace

PrometheusStartBridge::PrometheusStartBridge(BrowserWindow* window, QObject* parent)
    : QObject(parent)
    , m_window(window)
{
}

void PrometheusStartBridge::openAgentWithPrompt(const QString& prompt)
{
    if (!m_window) {
        return;
    }

    SideBarManager* mgr = m_window->sideBarManager();
    if (!mgr) {
        return;
    }

    const bool alreadyOpen = (mgr->activeSideBar() == QSL("PrometheusAgent"));

    if (alreadyOpen) {
        // Sidebar already showing PrometheusAgent: retrieve existing widget before calling
        // showSideBar (which returns early when toggle=false and id == m_activeBar).
        SideBar* sb = m_window->addSideBar();
        AgentRuntimeSidebarWidget* agentWidget = nullptr;
        if (sb && sb->layout() && sb->layout()->count() >= 2) {
            agentWidget = qobject_cast<AgentRuntimeSidebarWidget*>(sb->layout()->itemAt(1)->widget());
        }
        if (agentWidget) {
            agentWidget->seedPromptAndOpen(prompt);
        }
        mgr->showSideBar(QSL("PrometheusAgent"), false);
    } else {
        // Sidebar not yet showing PrometheusAgent: showSideBar creates the widget, then retrieve it.
        mgr->showSideBar(QSL("PrometheusAgent"), false);
        SideBar* sb = m_window->addSideBar();
        AgentRuntimeSidebarWidget* agentWidget = nullptr;
        if (sb && sb->layout() && sb->layout()->count() >= 2) {
            agentWidget = qobject_cast<AgentRuntimeSidebarWidget*>(sb->layout()->itemAt(1)->widget());
        }
        if (agentWidget) {
            agentWidget->seedPromptAndOpen(prompt);
        }
    }
}

void PrometheusStartBridge::navigateTo(const QString& url)
{
    // SECURITY: only allow http and https — reject javascript:, data:, falkon:, file:, etc.
    QUrl qurl(url);
    if (qurl.scheme() != QL1S("http") && qurl.scheme() != QL1S("https")) {
        return;
    }
    if (m_window && m_window->weView()) {
        m_window->weView()->load(qurl);
    }
}

QString PrometheusStartBridge::bookmarkFavoritesJson() const
{
    QJsonArray result;
    BookmarkItem* root = mApp->bookmarks()->rootItem();
    QList<BookmarkItem*> queue = root->children();
    int count = 0;
    while (!queue.isEmpty() && count < 8) {
        BookmarkItem* item = queue.takeFirst();
        if (item->isUrl()) {
            const QString host = item->url().host();
            const QString mono = host.left(2).toUpper();
            QJsonObject obj;
            obj[QSL("id")]    = QSL("bm-%1").arg(count);
            obj[QSL("name")]  = item->title();
            obj[QSL("url")]   = item->urlString();
            obj[QSL("mono")]  = mono;
            obj[QSL("color")] = deterministicColor(host);
            result.append(obj);
            ++count;
        } else if (item->isFolder()) {
            queue.append(item->children());
        }
    }
    return QString::fromUtf8(QJsonDocument(result).toJson(QJsonDocument::Compact));
}

QString PrometheusStartBridge::currentTheme() const
{
    Settings settings;
    const bool dark = settings.value(QSL("Interface/PrometheusThemeDark"), true).toBool();
    return dark ? QSL("dark") : QSL("light");
}
